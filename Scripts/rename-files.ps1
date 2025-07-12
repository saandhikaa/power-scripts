param (
    [string]$ListFile = ".\list.txt",
    [string]$Extension = "",               # e.g. ".pdf"
    [string[]]$Include = @(),              # e.g. @("FolderA", "FolderB")
    [string[]]$Exclude = @()               # e.g. @("DoNotTouch")
)

# Timestamped log files
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmm"
$logFile = ".\rename_log_$timestamp.csv"
$notFoundFile = ".\not_found_list_$timestamp.txt"

# Init log files
"OldFilePath,NewFilePath,Timestamp" | Out-File -FilePath $logFile -Encoding UTF8
"" | Out-File -FilePath $notFoundFile -Encoding UTF8  # Empty init

# Normalize extension
if ($Extension -and -not $Extension.StartsWith(".")) {
    $Extension = ".$Extension"
}

# Base path for relative references
$basePath = (Get-Location).Path

# Process mappings
Get-Content $ListFile | ForEach-Object {
    $parts = $_ -split "\s*,\s*"

    if ($parts.Length -ne 2) {
        Write-Warning "Invalid line: $_"
        return
    }

    $oldName = $parts[0].Trim()
    $newName = $parts[1].Trim()

    # Gather matching files
    $files = Get-ChildItem -Path . -Recurse -File | Where-Object {
        $_.FullName -notmatch '\\(_print|collecting)\\'
    }

    if ($Extension) {
        $files = $files | Where-Object { $_.Extension -ieq $Extension }
    }

    $files = $files | Where-Object {
        $_.BaseName -eq $oldName
    }

    # Apply folder filters
    $filteredFiles = @()

    foreach ($file in $files) {
        $relativePath = $file.FullName.Substring($basePath.Length + 1)
        $topFolder = $relativePath.Split([IO.Path]::DirectorySeparatorChar)[0]

        $includeCheck = ($Include.Count -eq 0 -or $Include -contains $topFolder)
        $excludeCheck = ($Exclude -contains $topFolder)

        if ($includeCheck -and -not $excludeCheck) {
            $filteredFiles += $file
        }
    }

    if ($filteredFiles.Count -eq 0) {
        # Log only the missing oldName (not full path)
        $oldName | Out-File -FilePath $notFoundFile -Append -Encoding UTF8
        Write-Host "Not found: $oldName"
        return
    }

    foreach ($file in $filteredFiles) {
        $newFileName = "$newName$($file.Extension)"
        $newPath = Join-Path -Path $file.DirectoryName -ChildPath $newFileName

        try {
            Rename-Item -Path $file.FullName -NewName $newPath -ErrorAction Stop

            $relativeOld = $file.FullName.Substring($basePath.Length + 1)
            $relativeNew = $newPath.Substring($basePath.Length + 1)

            Write-Host "Renamed '$relativeOld' → '$relativeNew'"

            "$relativeOld,$relativeNew,$([DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss"))" |
                Out-File -FilePath $logFile -Append -Encoding UTF8
        }
        catch {
            Write-Warning "Failed to rename '$($file.FullName)': $_"
        }
    }
}
