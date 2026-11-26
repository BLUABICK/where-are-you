param([Parameter(Mandatory=$true)][string]$CharacterId, [string]$SheetPath, [string]$OutputPath, [switch]$PreserveNative)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Collections.Generic;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
public static class SupportingPoseSplit {
 public static void Run(string input, string output, string id, bool preserveNative) {
  using(var sheet=new Bitmap(input)) {
   int w=sheet.Width,h=sheet.Height; var labels=new int[w*h]; var queue=new int[w*h];
   var bounds=new List<Rectangle>(); var rows=new List<int>();
   int component=0;
   for(int sy=0;sy<h;sy++)for(int sx=0;sx<w;sx++) {
    int seed=sy*w+sx; if(labels[seed]!=0 || sheet.GetPixel(sx,sy).A<32)continue;
    component++;int head=0,tail=1;queue[0]=seed;labels[seed]=component;
    int left=sx,right=sx,top=sy,bottom=sy;
    while(head<tail){int p=queue[head++],x=p%w,y=p/w;left=Math.Min(left,x);right=Math.Max(right,x);top=Math.Min(top,y);bottom=Math.Max(bottom,y);
     for(int dy=-1;dy<=1;dy++)for(int dx=-1;dx<=1;dx++){int nx=x+dx,ny=y+dy;if(nx<0||ny<0||nx>=w||ny>=h)continue;int np=ny*w+nx;if(labels[np]==0&&sheet.GetPixel(nx,ny).A>=32){labels[np]=component;queue[tail++]=np;}}
    }
    if(tail>8000){bounds.Add(Rectangle.FromLTRB(left,top,right+1,bottom+1));}
   }
   bounds.Sort((a,b)=>{int ar=a.Top>h/2?1:0,br=b.Top>h/2?1:0;return ar!=br?ar.CompareTo(br):a.Left.CompareTo(b.Left);});
   if(bounds.Count!=12)throw new Exception("Expected 12 silhouettes; found "+bounds.Count);
   int maxHeight=0,maxWidth=0;
   foreach(var r in bounds){maxHeight=Math.Max(maxHeight,r.Height);maxWidth=Math.Max(maxWidth,r.Width);}
   double scale=Math.Min(480.0/maxHeight,328.0/maxWidth);
   if(preserveNative)scale=Math.Min(1.0,scale);
   string[] names={"neutral","clasped","hand_on_hip","arms_crossed","thoughtful","relaxed","explaining","hands_behind","holding_wrist","neck_touch","hand_on_stomach","open_palms"};
   for(int i=0;i<12;i++){
    var r=bounds[i];int headL=w,headR=0;
    for(int y=r.Top;y<Math.Min(r.Top+55,r.Bottom);y++)for(int x=r.Left;x<r.Right;x++)if(sheet.GetPixel(x,y).A>=128){headL=Math.Min(headL,x);headR=Math.Max(headR,x);}
    double center=(headL+headR)/2.0;int dw=(int)Math.Round(r.Width*scale),dh=(int)Math.Round(r.Height*scale);
    int xout=(int)Math.Round(180+(r.Left-center)*scale);
    if(xout<8||xout+dw>352) { xout=(360-dw)/2; }
    using(var sprite=new Bitmap(360,520,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(sprite)){
     g.CompositingMode=CompositingMode.SourceCopy;g.InterpolationMode=preserveNative?InterpolationMode.HighQualityBicubic:InterpolationMode.NearestNeighbor;g.PixelOffsetMode=PixelOffsetMode.Half;
     if(preserveNative && scale==1.0) {
      using(var crop=sheet.Clone(r,PixelFormat.Format32bppArgb))g.DrawImageUnscaled(crop,xout,16);
     } else {
      g.DrawImage(sheet,new Rectangle(xout,16,dw,dh),r,GraphicsUnit.Pixel);
     }
     sprite.Save(System.IO.Path.Combine(output,id+"_"+(i+1).ToString("D2")+"_"+names[i]+".png"),ImageFormat.Png);
    }
    Console.WriteLine(id+" "+(i+1).ToString("D2")+" bounds="+r+" output=360x520"+(r.Left==0||r.Right==w?" SOURCE_EDGE_CONTACT":""));
   }
  }
 }
}
'@
$projectRoot = Split-Path $PSScriptRoot -Parent
if (-not $SheetPath) { $SheetPath = Join-Path $projectRoot "source_assets/art/characters/supporting/$CharacterId/${CharacterId}_12_poses.png" }
if (-not $OutputPath) { $OutputPath = Join-Path $projectRoot "assets/sprites/characters/$CharacterId/poses" }
New-Item -ItemType Directory -Force -Path $outputPath | Out-Null
[SupportingPoseSplit]::Run($SheetPath, $OutputPath, $CharacterId, $PreserveNative.IsPresent)
