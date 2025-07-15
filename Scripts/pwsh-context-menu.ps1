param (
    [switch]$Enable,
    [switch]$Disable
)

$MenuPath = 'Registry::HKEY_CLASSES_ROOT\Directory\shell\PowerShell7'
$MenuBgPath = 'Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\PowerShell7'
$PwshPath = 'C:\Program Files\PowerShell\7\pwsh.exe'

# Admin Check
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $IsAdmin) {
    Write-Host "This script requires Administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Yellow
    exit
}

function Add-ContextMenu {
    Write-Host "Adding PowerShell 7 context menu..."

    foreach ($Path in @($MenuPath, $MenuBgPath)) {
        New-Item -Path $Path -Force | Out-Null
        Set-ItemProperty -Path $Path -Name '(default)' -Value 'Open in PowerShell 7'
        Set-ItemProperty -Path $Path -Name 'Icon' -Value $PwshPath

        $CommandPath = Join-Path $Path 'command'
        New-Item -Path $CommandPath -Force | Out-Null
        Set-ItemProperty -Path $CommandPath -Name '(default)' `
            -Value "`"$PwshPath`" -NoExit -Command Set-Location -LiteralPath '%V'"
    }

    Write-Host "Context menu added successfully!" -ForegroundColor Green
}

function Remove-ContextMenu {
    foreach ($Path in @($MenuPath, $MenuBgPath)) {
        if (Test-Path $Path) {
            Remove-Item -Path $Path -Recurse -Force
            Write-Host "Removed context menu from $Path" -ForegroundColor Yellow
        }
    }
}

if ($Enable) {
    Add-ContextMenu
} elseif ($Disable) {
    Remove-ContextMenu
} else {
    Write-Host "Usage:"
    Write-Host "  pwsh-context-menu.ps1 -Enable    # Add context menu"
    Write-Host "  pwsh-context-menu.ps1 -Disable   # Remove context menu"
}
