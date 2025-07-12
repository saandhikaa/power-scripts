param (
    [string]$ConvertToMp3,
    [string]$ConvertToMp4,
    [string]$ExtractAudio,
    [string]$ExtractAudioMp3,
    [string]$Video,
    [string]$Audio,
    [string]$Output,
    [switch]$Merge,
    [string]$EditTag
)

# Import helper functions
. "$HOME\Documents\PowerShell\Modules\helpers.ps1"

# ffmpeg path
$ffmpegPath = "$HOME\Documents\PowerShell\Library\ytdlp\ffmpeg.exe"

if (-not (Test-Path $ffmpegPath)) {
    Write-Host "❌ ffmpeg.exe not found at $ffmpegPath"
    exit 1
}

# Show help if no operation
if (-not ($Merge -or $ConvertToMp3 -or $ConvertToMp4 -or $ExtractAudio -or $ExtractAudioMp3 -or $EditTag)) {

    Write-Host @"
🧰 Usage:
  ffmpeg.ps1 -Merge -Video "video.mp4" -Audio "audio.m4a"
  ffmpeg.ps1 -ExtractAudio "video.mp4"
  ffmpeg.ps1 -ExtractAudioMp3 "video.mp4"
  ffmpeg.ps1 -ConvertToMp3 "track.wav"
  ffmpeg.ps1 -ConvertToMp4 "clip.mov"
  ffmpeg.ps1 -EditTag "Music.mp3"

📦 ffmpeg path: $ffmpegPath
"@
    exit 0
}

# === Merge Audio + Video ===
if ($Merge) {
    Check-InvalidChars $Video
    Check-InvalidChars $Audio

    if (-not ($Video -and $Audio)) {
        Write-Host "❌ Missing -Video or -Audio"
        exit 1
    }
    if (-not $Output) {
        $Output = "$([IO.Path]::GetFileNameWithoutExtension($Video)).merged.mp4"
    }
    & $ffmpegPath -i $Video -i $Audio -c:v copy -c:a aac -strict experimental -y $Output
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Merged: $Output"
    } else {
        Write-Host "❌ Merge failed."
    }
    exit 0
}

# === Extract M4A ===
if ($ExtractAudio) {
    Check-InvalidChars $ExtractAudio
    $input = $ExtractAudio
    if (-not (Test-Path $input)) {
        Write-Host "❌ File not found: $input"
        exit 1
    }
    $output = $Output
    if (-not $output) {
        $output = "$([IO.Path]::GetFileNameWithoutExtension($input)).m4a"
    }
    & $ffmpegPath -i $input -vn -acodec copy -y $output
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Extracted M4A: $output"
    } else {
        Write-Host "❌ Failed to extract M4A."
    }
    exit 0
}

# === Extract MP3 ===
if ($ExtractAudioMp3) {
    Check-InvalidChars $ExtractAudioMp3
    $input = $ExtractAudioMp3
    if (-not (Test-Path $input)) {
        Write-Host "❌ File not found: $input"
        exit 1
    }
    $output = $Output
    if (-not $output) {
        $output = "$([IO.Path]::GetFileNameWithoutExtension($input)).mp3"
    }
    & $ffmpegPath -i $input -vn -ar 44100 -ac 2 -b:a 192k -y $output
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Extracted MP3: $output"
    } else {
        Write-Host "❌ Failed to extract MP3."
    }
    exit 0
}

# === Convert to MP3 ===
if ($ConvertToMp3) {
    Check-InvalidChars $ConvertToMp3
    $input = $ConvertToMp3
    if (-not (Test-Path $input)) {
        Write-Host "❌ File not found: $input"
        exit 1
    }
    $output = $Output
    if (-not $output) {
        $output = "$([IO.Path]::GetFileNameWithoutExtension($input)).mp3"
    }
    & $ffmpegPath -i $input -ar 44100 -ac 2 -b:a 192k -y $output
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Converted to MP3: $output"
    } else {
        Write-Host "❌ MP3 conversion failed."
    }
    exit 0
}

# === Convert to MP4 ===
if ($ConvertToMp4) {
    Check-InvalidChars $ConvertToMp4
    $input = $ConvertToMp4
    if (-not (Test-Path $input)) {
        Write-Host "❌ File not found: $input"
        exit 1
    }
    $output = $Output
    if (-not $output) {
        $output = "$([IO.Path]::GetFileNameWithoutExtension($input)).mp4"
    }
    & $ffmpegPath -i $input -y $output
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Converted to MP4: $output"
    } else {
        Write-Host "❌ MP4 conversion failed."
    }
    exit 0
}

# === Edit MP3 Tag ===
if ($EditTag) {
    Check-InvalidChars $EditTag

    $input = $EditTag
    if (-not (Test-Path $input)) {
        Write-Host "❌ File not found: $input"
        exit 1
    }

    # Ask user for metadata
    $title = Read-Host "🎵 Song Title (leave blank to skip)"
    $artist = Read-Host "👤 Artist (leave blank to skip)"
    $album = Read-Host "💿 Album (leave blank to skip)"
    $cover = Select-ImageFile -Prompt "🖼️ Cover Image (optional): Please choose a file"

    # Build metadata args
    $metadataArgs = @()
    if ($title)  { $metadataArgs += "-metadata"; $metadataArgs += "title=$title" }
    if ($artist) { $metadataArgs += "-metadata"; $metadataArgs += "artist=$artist" }
    if ($album)  { $metadataArgs += "-metadata"; $metadataArgs += "album=$album" }

    $output = "$([IO.Path]::GetFileNameWithoutExtension($input)).tagged.mp3"

    if ($cover -and (Test-Path $cover)) {
        & $ffmpegPath -i $input -i $cover -map 0 -map 1 `
            @metadataArgs `
            -c copy -id3v2_version 3 -y $output
    } else {
        & $ffmpegPath -i $input `
            @metadataArgs `
            -c copy -id3v2_version 3 -y $output
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Metadata updated: $output"
    } else {
        Write-Host "❌ Metadata update failed."
    }

    exit 0
}
