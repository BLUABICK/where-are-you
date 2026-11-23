param([string]$SheetFile = 'artem_12_poses_eyes_v2.png', [string]$CharacterId = 'artem')
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies 'System.Drawing.Common','System.Drawing.Primitives' -TypeDefinition @'
using System.Drawing;
public static class ArtemAlphaCleanup {
    public static int[] Labels;
    public static int[,] Components(Bitmap image) {
        int w=image.Width,h=image.Height;
        Labels=new int[w*h];
        int[] queue=new int[w*h];
        int[,] stats=new int[w*h/2,5];
        int id=0;
        for(int sy=0;sy<h;sy++) for(int sx=0;sx<w;sx++) {
            int seed=sy*w+sx;
            if(Labels[seed]!=0 || image.GetPixel(sx,sy).A<8) continue;
            id++;
            int head=0,tail=1;
            queue[0]=seed; Labels[seed]=id;
            int minx=sx,maxx=sx,miny=sy,maxy=sy;
            while(head<tail) {
                int p=queue[head++],x=p%w,y=p/w;
                minx=System.Math.Min(minx,x); maxx=System.Math.Max(maxx,x);
                miny=System.Math.Min(miny,y); maxy=System.Math.Max(maxy,y);
                for(int dy=-1;dy<=1;dy++) for(int dx=-1;dx<=1;dx++) {
                    int nx=x+dx,ny=y+dy;
                    if(nx<0 || ny<0 || nx>=w || ny>=h) continue;
                    int np=ny*w+nx;
                    if(Labels[np]==0 && image.GetPixel(nx,ny).A>=8) {
                        Labels[np]=id; queue[tail++]=np;
                    }
                }
            }
            stats[id,0]=tail; stats[id,1]=minx; stats[id,2]=miny; stats[id,3]=maxx; stats[id,4]=maxy;
        }
        int[,] result=new int[id+1,5];
        for(int i=1;i<=id;i++) for(int j=0;j<5;j++) result[i,j]=stats[i,j];
        return result;
    }
    public static Bitmap Extract(Bitmap sheet,int id,int centerX,int rowY) {
        Bitmap output=new Bitmap(360,520,System.Drawing.Imaging.PixelFormat.Format32bppArgb);
        for(int y=0;y<sheet.Height;y++) for(int x=0;x<sheet.Width;x++) {
            if(Labels[y*sheet.Width+x]!=id) continue;
            int dx=x-centerX+180,dy=y-rowY+16;
            if(dx<0 || dx>=360 || dy<0 || dy>=520) throw new System.Exception("Sprite would be clipped");
            output.SetPixel(dx,dy,sheet.GetPixel(x,y));
        }
        return output;
    }
    public static void Clean(Bitmap image) {
        for (int y=0;y<image.Height;y++) for (int x=0;x<image.Width;x++) {
            Color c=image.GetPixel(x,y);
            if(c.A==0) continue;
            bool red=c.R>230 && c.G<65 && c.B<85;
            bool blue=c.B>230 && c.R<65 && c.G<85;
            bool green=c.G>230 && c.R<65 && c.B<85;
            bool yellow=c.R>230 && c.G>230 && c.B<60;
            bool magenta=c.R>230 && c.B>230 && c.G<60;
            // Remove neon generation fringe; preserve illustrated clothing/skin.
            if(red || blue || green || yellow || magenta) image.SetPixel(x,y,Color.Transparent);
        }
    }
}
'@
$root = Split-Path $PSScriptRoot -Parent
$inputPath = Join-Path (Join-Path $root ('assets/sprites/characters/'+$CharacterId)) $SheetFile
$outputPath = Join-Path $root ('assets/sprites/characters/'+$CharacterId+'/poses')
New-Item -ItemType Directory -Force -Path $outputPath | Out-Null
$sheet = [System.Drawing.Bitmap]::new($inputPath)
if ($sheet.Height -ne 958) {
    $scaled = [System.Drawing.Bitmap]::new([int][Math]::Round($sheet.Width*958/$sheet.Height),958,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($scaled)
    $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $g.DrawImage($sheet,[System.Drawing.Rectangle]::new(0,0,$scaled.Width,958),0,0,$sheet.Width,$sheet.Height,[System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose(); $sheet.Dispose(); $sheet=$scaled
}
[ArtemAlphaCleanup]::Clean($sheet)
# The rows meet at y=479; these six pixels contain first-row cutoff remnants.
$gapStart = if ($CharacterId -eq 'artem') { 479 } else { 478 }
$gapEnd = if ($CharacterId -eq 'artem') { 485 } else { 481 }
for ($y=$gapStart; $y -lt $gapEnd; $y++) {
    for ($x=0; $x -lt $sheet.Width; $x++) { $sheet.SetPixel($x,$y,[System.Drawing.Color]::Transparent) }
}
$names = @('neutral','clasped','hand_on_hip','arms_crossed','thoughtful','relaxed','explaining','hands_behind','holding_wrist','neck_touch','hand_on_stomach','open_palms')
$stats = [ArtemAlphaCleanup]::Components($sheet)
$figures = @(for ($id=1; $id -lt $stats.GetLength(0); $id++) {
    if ($stats[$id,0] -gt 10000) {
        [pscustomobject]@{ Id=$id; Pixels=$stats[$id,0]; Left=$stats[$id,1]; Top=$stats[$id,2]; Right=$stats[$id,3]; Bottom=$stats[$id,4]; Row=[int]($stats[$id,2] -gt 479) }
    }
}) | Sort-Object Row,Left
if ($figures.Count -ne 12) { throw "Expected 12 separate silhouettes, found $($figures.Count)" }
for ($i = 0; $i -lt 12; $i++) {
    $figure=$figures[$i]
    # Align by the head, not by hands/gestures or a guessed sheet cell.
    $headLeft=1642; $headRight=0
    for ($y=$figure.Top; $y -lt ($figure.Top+70); $y++) {
        for ($x=$figure.Left; $x -le $figure.Right; $x++) {
            if ([ArtemAlphaCleanup]::Labels[$y*$sheet.Width+$x] -eq $figure.Id) {
                $headLeft=[Math]::Min($headLeft,$x); $headRight=[Math]::Max($headRight,$x)
            }
        }
    }
    $center=[int][Math]::Round(($headLeft+$headRight)/2)
    $canvas=[ArtemAlphaCleanup]::Extract($sheet,$figure.Id,$center,($figure.Row*479))
    $canvas.Save((Join-Path $outputPath ('{0}_{1:d2}_{2}.png' -f $CharacterId,($i+1),$names[$i])),[System.Drawing.Imaging.ImageFormat]::Png)
    $canvas.Dispose()
    Write-Output ("Pose {0:d2}: source x={1}..{2}, pixels={3}; full silhouette preserved" -f ($i+1),$figure.Left,$figure.Right,$figure.Pixels)
}
$sheet.Dispose()
Write-Output 'Split complete: 12 RGBA poses, each 360x520; consistent origin and scale.'
