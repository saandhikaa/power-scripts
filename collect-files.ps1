param (
    [string[]]$Files,  # Array of file names to copy (can be with or without extension)
    [string]$List,     # Path to a text file containing the list of files to collect
    [string]$Output    # Custom folder name for the destination
)

# Set the destination directory path
$collectingDir = "collecting"
$destinationDir = "$collectingDir\$Output"

# Create the destination directory if it doesn't exist
If (-not (Test-Path -Path $destinationDir)) {
    New-Item -ItemType Directory -Path $destinationDir | Out-Null
    Write-Host "Created destination directory: $destinationDir"
}

# Initialize a hashtable to track the file counts per folder
$folderFileCount = @{}

# Get the current working directory and escape backslashes for regex
$rootPath = [regex]::Escape((Get-Location).Path)

# If a list file is provided, read its contents and append to $Files
If ($List -and (Test-Path -Path $List)) {
    $Files += Get-Content -Path $List | Where-Object { $_ -match '\S' }  # Ignore empty lines
    Write-Host "Loaded files from list: $List"
}

# Log file path for missing files
$logFile = "$destinationDir\missing_files.log"
If (Test-Path $logFile) { Clear-Content -Path $logFile }  # Clear previous log

# Get all files from current and subfolders, explicitly excluding the "collecting" folder
$foundFiles = Get-ChildItem -Path . -Recurse -File | Where-Object { $_.FullName -notmatch "collecting\\" }

# Track missing files
$missingFiles = @()

# Process each file from the list
foreach ($file in $Files) {
    # Search for the file (with or without extension)
    $matchedFile = $foundFiles | Where-Object { 
        $_.Name -eq $file -or [System.IO.Path]::GetFileNameWithoutExtension($_.Name) -eq $file 
    }

    if ($matchedFile) {
        foreach ($fileObj in $matchedFile) {
            # Get the folder path of the current file (relative path)
            $relativePath = $fileObj.DirectoryName -replace "^$rootPath\\?", ""

            # Increment the file count for the folder
            If (-not $folderFileCount.ContainsKey($relativePath)) {
                $folderFileCount[$relativePath] = 0
            }
            $folderFileCount[$relativePath]++

            # Construct the destination path for each file
            $destPath = Join-Path -Path $destinationDir -ChildPath $fileObj.Name
            
            # Copy the file to the destination folder
            Copy-Item -Path $fileObj.FullName -Destination $destPath -Force
            Write-Host "$relativePath\$($fileObj.Name) collected!"
        }
    } else {
        Write-Host "WARNING: File '$file' not found!" -ForegroundColor Yellow
        $missingFiles += $file
    }
}

# Write missing files to log file
If ($missingFiles.Count -gt 0) {
    $missingFiles | Out-File -FilePath $logFile -Encoding utf8
    Write-Host "Missing files logged in: $logFile" -ForegroundColor Red
}

# Add a newline before the summary
Write-Host ""

# Echo the summary of collected files per folder
$folderFileCount.GetEnumerator() | ForEach-Object {
    Write-Host "$($_.Value) files collected from $($_.Key)"
}
