<#
.SYNOPSIS
    Antigravity global skill kurulum scripti (Windows PowerShell).
    gemini-image, gemini-music, gemini-video ve ui-design skillerini ~/.gemini/config/skills/ dizinine kurar.
#>

$ErrorActionPreference = "Stop"

$SourceSkills = Join-Path $PSScriptRoot "skills"
$TargetRoot   = Join-Path $env:USERPROFILE ".gemini\config\skills"

if (-not (Test-Path $SourceSkills)) {
    Write-Error "skills klasoru bulunamadi: $SourceSkills"
    exit 1
}

New-Item -ItemType Directory -Force -Path $TargetRoot | Out-Null

$Skills = @("gemini-image", "gemini-music", "gemini-video", "ui-design")

foreach ($skill in $Skills) {
    $src = Join-Path $SourceSkills $skill
    $dst = Join-Path $TargetRoot $skill

    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    Copy-Item -Path (Join-Path $src "SKILL.md") -Destination (Join-Path $dst "SKILL.md") -Force

    # references/ klasoru varsa icerigini temiz sekilde kopyala (ic ice references/ olusturmadan)
    $srcRefs = Join-Path $src "references"
    $dstRefs = Join-Path $dst "references"
    if (Test-Path $srcRefs) {
        New-Item -ItemType Directory -Force -Path $dstRefs | Out-Null
        Copy-Item -Path (Join-Path $srcRefs "*") -Destination $dstRefs -Recurse -Force
    }

    # usage-log.csv zaten varsa kullanicinin mevcut kota kaydini ezme
    $srcLog = Join-Path $src "usage-log.csv"
    $dstLog = Join-Path $dst "usage-log.csv"
    if ((Test-Path $srcLog) -and -not (Test-Path $dstLog)) {
        Copy-Item -Path $srcLog -Destination $dstLog
    }

    Write-Host "[OK] /$skill kuruldu -> $dst" -ForegroundColor Green
}

Write-Host ""
Write-Host "Kurulum tamamlandi!" -ForegroundColor Cyan
Write-Host "Antigravity'de yeni bir sohbet acarak /gemini-image, /gemini-music, /gemini-video ve /ui-design skillerini kullanabilirsiniz."
Write-Host ""
Write-Host "Hatirlatma:" -ForegroundColor Yellow
Write-Host "  1. Chrome'da Google AI Pro hesabiniz acik olsun."
Write-Host "  2. Chrome DevTools MCP baglantisi aktif olsun (chrome://inspect/#remote-debugging)."
Write-Host "  3. Video/ses/gorsel isleme icin ffmpeg ve ffprobe PATH uzerinde kurulu olsun."
