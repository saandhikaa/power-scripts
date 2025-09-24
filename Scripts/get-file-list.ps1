param (
    [switch]$IncludeHidden,   # Include hidden/system files and folders
    [switch]$WithExtension    # Keep file extensions in output
)

# Define output file path
$outputFile = "FileList.txt"

# Clear the file if it exists
if (Test-Path $outputFile) {
    Clear-Content $outputFile
}

# Build Get-ChildItem parameters
$gciParams = @{
    Path    = "."
    Recurse = $true
    File    = $true
}
if ($IncludeHidden) {
    $gciParams.Force = $true
}

# Get all files recursively
$files = Get-ChildItem @gciParams |
    Where-Object {
        # Exclude dot-folders like .git, .vscode, .idea, etc.
        -not ($_.DirectoryName -match '\\\.[^\\]*')
    } |
    Select-Object DirectoryName, @{
        Name       = "FileName"
        Expression = {
            if ($WithExtension) {
                $_.Name
            } else {
                [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
            }
        }
    }

$total = $files.Count
$lastDir = ""
$counter = 0

# Write-Host "Exporting $total files to $outputFile..."
# Write-Host ""

# Loop through each file and write to output file
$files | ForEach-Object {
    $counter++

    # Progress bar
    $percent = [math]::Round(($counter / $total) * 100, 2)
    Write-Progress -Activity "Exporting files..." -Status "$counter of $total ($percent%)" -PercentComplete $percent

    # Write directory header if changed
    if ($_.DirectoryName -ne $lastDir) {
        "`n[$($_.DirectoryName)]" | Out-File -Append -Encoding UTF8 $outputFile
        $lastDir = $_.DirectoryName
    }

    # Write file name
    $_.FileName | Out-File -Append -Encoding UTF8 $outputFile
}

# Clear progress bar
Write-Progress -Activity "Exporting files..." -Completed

Write-Host "File list exported to $outputFile successfully!"
