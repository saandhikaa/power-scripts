# Script to recursively rename PDF files by removing "-Layout1" or "-Model" from the filenames
Get-ChildItem -Path . -Recurse -Filter "*.pdf" | ForEach-Object {
    # Extract the full path and the current file name
    $oldName = $_.FullName

    # Remove "-Layout1" or "-Model" from the file name
    $newName = $_.DirectoryName + "\" + ($_.BaseName -replace "-(Layout1|Model)$", "") + $_.Extension

    # Rename the file if the name changes
    If ($oldName -ne $newName) {
        Rename-Item -Path $oldName -NewName $newName
        Write-Host "Renamed: $oldName -> $newName"
    }
}
