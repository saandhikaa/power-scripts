param (
    [string]$url,         # URL of the video
    [switch]$AudioOnly    # Parameter to indicate if only audio should be downloaded
)

# Set the base path to yt-dlp
$ytDlpPath = "C:\Users\SANDHIKA\App\yt-dlp\yt-dlp.exe"

# Check if AudioOnly is specified
if ($AudioOnly) {
    # Download audio only
    & $ytDlpPath -f bestaudio $url
} else {
    # Download best video and best audio, merge into mp4
    & $ytDlpPath -f bestvideo+bestaudio --merge-output-format mp4 $url
}
