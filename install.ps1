<#
.SYNOPSIS
    Antigravity global skill kurulum scripti (Windows PowerShell).
    skills/ altindaki tum skilleri (gemini-image, gemini-music, gemini-video, gemini-reels,
    local-tts, elevenlabs-tts, ui-design) ~/.gemini/config/skills/ dizinine kurar.
    Ayni isimde skill varsa once yedekler; mevcut usage-log.csv ve .env dosyalarini korur.
.EXAMPLE
    .\install.ps1
    .\install.ps1 -Only gemini-reels,elevenlabs-tts
#>
param(
    [string[]]$Only,
    [string]$Target = (Join-Path $env:USERPROFILE ".gemini\config\skills")
)
$ErrorActionPreference = "Stop"

$SourceSkills = Join-Path $PSScriptRoot "skills"
if (-not (Test-Path $SourceSkills)) { Write-Error "skills klasoru bulunamadi: $SourceSkills"; exit 1 }

$Skills = Get-ChildItem $SourceSkills -Directory | Select-Object -ExpandProperty Name
if ($Only) {
    $Only = $Only | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    $Skills = $Skills | Where-Object { $Only -contains $_ }
}
if (-not $Skills) { Write-Error "Kurulacak skill bulunamadi."; exit 1 }

New-Item -ItemType Directory -Force -Path $Target | Out-Null
$Backup = Join-Path (Split-Path $Target -Parent) ("skills-backup-" + (Get-Date -Format "yyyyMMdd-HHmmss"))

foreach ($skill in $Skills) {
    $src = Join-Path $SourceSkills $skill
    $dst = Join-Path $Target $skill
    $keep = @{}
    if (Test-Path $dst) {
        foreach ($k in "usage-log.csv", ".env") { $p = Join-Path $dst $k; if (Test-Path $p) { $keep[$k] = [System.IO.File]::ReadAllBytes($p) } }
        New-Item -ItemType Directory -Force -Path $Backup | Out-Null
        [System.IO.Directory]::Move($dst, (Join-Path $Backup $skill))   # .NET move also works with 8.3 short paths
    }
    Copy-Item -Path $src -Destination $dst -Recurse
    foreach ($k in $keep.Keys) { [System.IO.File]::WriteAllBytes((Join-Path $dst $k), $keep[$k]) }
    Write-Host "[OK] /$skill kuruldu -> $dst" -ForegroundColor Green
}
if (Test-Path $Backup) { Write-Host "Eski surumler yedeklendi: $Backup" -ForegroundColor Yellow }

Write-Host ""
Write-Host "Kurulum tamamlandi! Antigravity'de yeni bir sohbet acin." -ForegroundColor Cyan
Write-Host "Hatirlatma:" -ForegroundColor Yellow
Write-Host "  1. Chrome'da Google AI Pro hesabiniz acik olsun."
Write-Host "  2. Chrome DevTools MCP baglantisi aktif olsun (chrome://inspect/#remote-debugging)."
Write-Host "  3. ffmpeg ve ffprobe PATH uzerinde kurulu olsun."
if (($Skills -contains "elevenlabs-tts") -and -not ([Environment]::GetEnvironmentVariable("ELEVENLABS_API_KEY", "User") -or $env:ELEVENLABS_API_KEY)) {
    Write-Host "  4. ELEVENLABS_API_KEY ayarli degil (sadece elevenlabs-tts icin; local-tts ucretsiz)." -ForegroundColor Yellow
}
if (($Skills -contains "local-tts") -and -not (Test-Path (Join-Path $env:USERPROFILE ".local-tts\venv\Scripts\python.exe"))) {
    Write-Host "  5. Ucretsiz yerel sesler icin bir kez (~1,5 GB): powershell -ExecutionPolicy Bypass -File `"$Target\local-tts\scripts\setup.ps1`" -Warmup" -ForegroundColor Yellow
}
