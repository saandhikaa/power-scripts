# Define output file path
$outputFile = "FileList.txt"

# Clear the file if it exists
if (Test-Path $outputFile) {
    Clear-Content $outputFile
}

# Get all files recursively and extract the directory name + file name without extension
$files = Get-ChildItem -Path . -Recurse -File | 
    Select-Object DirectoryName, @{Name="FileName"; Expression={[System.IO.Path]::GetFileNameWithoutExtension($_.Name)}} 

$lastDir = ""

# Loop through each file and write to output file
$files | ForEach-Object {
    if ($_.DirectoryName -ne $lastDir) {
        "`n[$($_.DirectoryName)]" | Out-File -Append -Encoding UTF8 $outputFile
        $lastDir = $_.DirectoryName
    }
    $_.FileName | Out-File -Append -Encoding UTF8 $outputFile
}

Write-Host "File list exported to $outputFile successfully!"