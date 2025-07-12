# helpers.ps1

function Check-InvalidChars {
    param([string]$path)

    $invalidChars = '[\[\]\(\)\|\&\^\!\<\>\*\?]'
    if ($path -match $invalidChars) {
        Write-Host "❌ File name contains unsupported special characters like [ ] ( ) etc."
        Write-Host "💡 Please rename the file or escape the characters manually in PowerShell."
        exit 1
    }
}


function Select-ImageFile {
    [CmdletBinding()]
    param (
        [string]$Title = "🖼️ Select an image file",
        [string]$Prompt = "🖼️ Please select an image...",
        [string]$PromptColor = "White",
        [string[]]$Extensions = @("*.jpg", "*.jpeg", "*.png", "*.bmp", "*.gif")
    )

    if ($Prompt) {
        Write-Host "$Prompt" -ForegroundColor $PromptColor
    }

    Add-Type -AssemblyName System.Windows.Forms

    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = $Title
    $dialog.Filter = ($Extensions | ForEach-Object { "$_ files ($_)|$_" }) -join "|"
    $dialog.Multiselect = $false
    $dialog.InitialDirectory = [Environment]::GetFolderPath('MyPictures')

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.FileName
    } else {
        return ""
    }
}
