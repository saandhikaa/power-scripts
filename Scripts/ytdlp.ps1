param (
    [string]$url,
    [switch]$AudioOnly,
    [int]$Quality,
    [switch]$Subtitles,
    [switch]$SubtitleOnly
)

# === Setup paths ===
$ytDlpFolder = "$HOME\Documents\PowerShell\Library\ytdlp"
$ytDlpPath = Join-Path $ytDlpFolder "yt-dlp.exe"
$ffmpegPath = Join-Path $ytDlpFolder "ffmpeg.exe"

# === Create tool folder if missing ===
if (-not (Test-Path $ytDlpFolder)) {
    New-Item -ItemType Directory -Path $ytDlpFolder -Force | Out-Null
}

# === Check yt-dlp ===
if (-not (Test-Path $ytDlpPath)) {
    Write-Host "❌ yt-dlp.exe not found in $ytDlpFolder"
    $confirm = Read-Host "Do you want to download yt-dlp.exe now? (Y/N)"
    if ($confirm -match '^[Yy]$') {
        try {
            Invoke-WebRequest -Uri "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe" -OutFile $ytDlpPath
            Write-Host "✅ Downloaded yt-dlp.exe"
        } catch {
            Write-Error "❌ Failed to download yt-dlp: $_"
            exit 1
        }
    } else {
        Write-Host "Download cancelled. Exiting."
        exit 1
    }
}

# === Check ffmpeg ===
if (-not (Test-Path $ffmpegPath)) {
    Write-Host "❌ ffmpeg.exe not found in $ytDlpFolder"
    $confirmFFMPEG = Read-Host "Do you want to download ffmpeg.exe now? (Y/N)"
    if ($confirmFFMPEG -match '^[Yy]$') {
        $tempZip = "$env:TEMP\ffmpeg.zip"
        $tempDir = "$env:TEMP\ffmpeg_extracted"

        try {
            Write-Host "📦 Downloading ffmpeg..."
            Invoke-WebRequest -Uri "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip" -OutFile $tempZip
            Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force
            $ffmpegExtracted = Get-ChildItem -Recurse -Path $tempDir -Filter "ffmpeg.exe" | Select-Object -First 1
            if ($ffmpegExtracted) {
                Copy-Item $ffmpegExtracted.FullName -Destination $ffmpegPath -Force
                Write-Host "✅ ffmpeg.exe copied to: $ffmpegPath"
            } else {
                Write-Error "❌ ffmpeg.exe not found in archive!"
                exit 1
            }

            Remove-Item $tempZip -Force
            Remove-Item $tempDir -Recurse -Force
        } catch {
            Write-Error "❌ Failed to install ffmpeg: $_"
            exit 1
        }
    } else {
        Write-Warning "⚠️ ffmpeg is required for merging and mp3 conversion. Some features may not work."
    }
}

# === Show help if no URL provided ===
if (-not $url) {
    Write-Host "`n💡 Usage:"
    Write-Host "  ytdlp.ps1 <url> [options]"
    Write-Host "`n📌 Options:"
    Write-Host "  -AudioOnly         Download best audio as MP3"
    Write-Host "  -Quality <number>  Max resolution (e.g., 720)"
    Write-Host "  -Subtitles         Download manual subtitles (all languages)"
    Write-Host "  -SubtitleOnly      Download only subtitles, no video/audio"
    Write-Host "`n🧪 Examples:"
    Write-Host "  ytdlp.ps1 https://youtube.com/watch?v=abc123"
    Write-Host "  ytdlp.ps1 https://youtube.com/watch?v=abc123 -AudioOnly"
    Write-Host "  ytdlp.ps1 https://youtube.com/watch?v=abc123 -Quality 720 -Subtitles"
    Write-Host "  ytdlp.ps1 https://youtube.com/watch?v=abc123 -SubtitleOnly"
    exit 0
}

# === Build yt-dlp command ===
$args = @()

# Force yt-dlp to use local ffmpeg if present
$args += "--ffmpeg-location"; $args += $ytDlpFolder

# Set output format for subtitles
if ($SubtitleOnly -or $Subtitles) {
    $args += "--output"; $args += "%(title)s/%(title)s.%(language)s.%(ext)s"
}

# Subtitle only
if ($SubtitleOnly) {
    $args += "--skip-download"
    $args += "--all-subs"
    $args += "--write-sub"
    $args += "--convert-subs"; $args += "srt"
    Write-Host "📄 Downloading manual subtitles only..."
}
# Audio only
elseif ($AudioOnly) {
    $args += "--extract-audio"
    $args += "--audio-format"; $args += "mp3"
    $args += "--audio-quality"; $args += "0"
    Write-Host "🎧 Downloading best audio only (MP3)..."
}
# Video
else {
    if ($Quality) {
        $formatSelector = "bestvideo[height<=$Quality]+bestaudio/best"
        Write-Host "📼 Downloading video up to ${Quality}p (fallback to best lower)..."
    } else {
        $formatSelector = "bestvideo+bestaudio"
        Write-Host "📼 Downloading best available video + audio..."
    }
    $args += "-f"; $args += $formatSelector
    $args += "--merge-output-format"; $args += "mp4"
}

# Subtitles with video/audio
if (-not $SubtitleOnly -and $Subtitles) {
    $args += "--all-subs"
    $args += "--write-sub"
    $args += "--convert-subs"; $args += "srt"
    Write-Host "📝 Downloading manual subtitles with video/audio..."
}

# Add URL last
$args += $url

# === Run yt-dlp ===
& $ytDlpPath @args
