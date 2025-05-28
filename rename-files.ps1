param (
    [string]$ListFile = ".\list.txt",
    [string]$Extension = "",               # e.g. ".pdf"
    [string[]]$Include = @(),              # e.g. @("FolderA", "FolderB")
    [string[]]$Exclude = @()               # e.g. @("DoNotTouch")
)

# Timestamped log file
$timestamp = Get-Date -Format "yyyy-MM-dd_HHmm"
$logFile = ".\rename_log_$timestamp.csv"
"OldFilePath,NewFilePath,Timestamp" | Out-File -FilePath $logFile -Encoding UTF8

# Normalize extension (ensure it starts with a dot)
if ($Extension -and -not $Extension.StartsWith(".")) {
    $Extension = ".$Extension"
}

# Load mapping
Get-Content $ListFile | ForEach-Object {
    $parts = $_ -split "\s*,\s*"

    if ($parts.Length -ne 2) {
        Write-Warning "Invalid line: $_"
        return
    }

    $oldName = $parts[0].Trim()
    $newName = $parts[1].Trim()

    # Collect matching files
    $files = Get-ChildItem -Path . -Recurse -File | Where-Object {
        # Skip files in folders named "_print" or "collecting" (at any level)
        $_.FullName -match '\\(_print|collecting)\\' -eq $false
    }

    if ($Extension) {
        $files = $files | Where-Object { $_.Extension -ieq $Extension }
    }

    $files = $files | Where-Object {
        $_.BaseName -eq $oldName
    }

    # Apply include and exclude filter based on top-level folder (only immediate children of current directory)
    $filteredFiles = @()

    foreach ($file in $files) {
        # Get relative path from current dir
        $relativePath = $file.FullName.Substring((Get-Location).Path.Length + 1)
        $topFolder = $relativePath.Split([IO.Path]::DirectorySeparatorChar)[0]

        $includeCheck = ($Include.Count -eq 0 -or $Include -contains $topFolder)
        $excludeCheck = ($Exclude -contains $topFolder)

        if ($includeCheck -and -not $excludeCheck) {
            $filteredFiles += $file
        }
    }

    foreach ($file in $filteredFiles) {
        $newFileName = "$newName$($file.Extension)"
        $newPath = Join-Path -Path $file.DirectoryName -ChildPath $newFileName

        try {
            Rename-Item -Path $file.FullName -NewName $newPath -ErrorAction Stop
            Write-Host "Renamed '$($file.FullName)' → '$newPath'"

            "$($file.FullName),$newPath,$([DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss"))" |
                Out-File -FilePath $logFile -Append -Encoding UTF8
        }
        catch {
            Write-Warning "Failed to rename '$($file.FullName)': $_"
        }
    }
}
