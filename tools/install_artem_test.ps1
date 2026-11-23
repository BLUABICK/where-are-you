$ErrorActionPreference = 'Stop'
$workspace = Split-Path $PSScriptRoot -Parent
$target = 'C:\Users\admin\Desktop\where are you'
if (-not (Test-Path -LiteralPath (Join-Path $target 'project.godot'))) { throw 'Godot project missing' }
$files = @('scenes/novel/artem_test.tscn','scripts/novel/artem_test.gd','dialogue/timelines/prologue/artem_test.dtl','notes/production/artem_test.md')
foreach ($relative in $files) {
    $destination = Join-Path $target $relative
    New-Item -ItemType Directory -Force -Path (Split-Path $destination -Parent) | Out-Null
    Copy-Item -LiteralPath (Join-Path (Join-Path $workspace 'staging') $relative) -Destination $destination
}
$artemTarget = Join-Path $target 'assets/sprites/characters/artem'
New-Item -ItemType Directory -Force -Path $artemTarget | Out-Null
Copy-Item -LiteralPath (Join-Path $workspace 'assets/sprites/characters/artem/poses') -Destination $artemTarget -Recurse -Force
Copy-Item -LiteralPath (Join-Path $workspace 'assets/sprites/characters/artem/artem_12_poses.png'),(Join-Path $workspace 'assets/sprites/characters/artem/artem_12_poses_prompt.txt') -Destination $artemTarget
$toolsTarget = Join-Path $target 'tools'
New-Item -ItemType Directory -Force -Path $toolsTarget | Out-Null
Copy-Item -LiteralPath (Join-Path $workspace 'tools/split_artem.ps1') -Destination $toolsTarget
New-Item -ItemType Directory -Force -Path (Join-Path $target 'temp/previews'),(Join-Path $target 'temp/logs') | Out-Null
$configPath = Join-Path $target 'project.godot'
$config = Get-Content -LiteralPath $configPath -Raw
Copy-Item -LiteralPath $configPath -Destination (Join-Path $target ('temp/logs/project_before_artem_' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.godot'))
if ($config -notmatch '(?m)^run/main_scene=') {
    $config = $config.Replace('[application]', '[application]' + "`n" + 'run/main_scene="res://scenes/novel/artem_test.tscn"')
}
if ($config -notmatch '(?m)^window/size/viewport_width=') {
    $config = $config.Replace('[display]', '[display]' + "`n" + 'window/size/viewport_width=1920' + "`n" + 'window/size/viewport_height=1080' + "`n" + 'window/size/window_width_override=1280' + "`n" + 'window/size/window_height_override=720')
}
Set-Content -LiteralPath $configPath -Value $config -Encoding utf8
Write-Output 'Installed Artem test scene, 12 sprites and Dialogic timeline; project configuration backed up.'
