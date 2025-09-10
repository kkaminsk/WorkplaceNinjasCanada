
# PowerShell App Deployment Toolkit Script for WinRAR Deployment
# Generated on September 10, 2025

## Import the PSADT functions
. "$PSScriptRoot\Deploy-Application.ps1"

## Application Details
$appVendor = "RARLAB"
$appName = "WinRAR"
$appVersion = "7.01"
$appArch = "x64"
$appLang = "EN"
$appRevision = "01"
$appScriptVersion = "1.0.0"
$appScriptDate = "2025-09-10"
$appScriptAuthor = "Grok"

## Installation Parameters
$installName = "$appVendor $appName $appVersion"
$installTitle = "$appName $appVersion"
$installerFile = "winrar-x64-701.exe"
$silentInstallSwitch = "/S"

## Source Files
$sourceFiles = Join-Path -Path $dirFiles -ChildPath $installerFile

## Main Deployment Logic
function Deploy-WinRAR {
    # Check if WinRAR is already installed
    $installed = Get-InstalledApplication -Name "WinRAR"
    if ($installed) {
        Write-Log -Message "$installName is already installed. Skipping installation." -Source $deployAppScriptFriendlyName
        Show-InstallationPrompt -Message "$installName is already installed on this system." -ButtonRightText "OK" -Icon Information
        Exit-Script -ExitCode 0
    }

    # Install WinRAR
    Write-Log -Message "Starting installation of $installName..." -Source $deployAppScriptFriendlyName
    Show-InstallationProgress -StatusMessage "Installing $installTitle. Please wait..."
    
    Execute-Process -Path "$sourceFiles" -Parameters $silentInstallSwitch -WaitForProcess -CreateNoWindow
    
    # Verify Installation
    $installedPost = Get-InstalledApplication -Name "WinRAR"
    if ($installedPost) {
        Write-Log -Message "$installName installed successfully." -Source $deployAppScriptFriendlyName
        Show-InstallationPrompt -Message "$installTitle has been installed successfully!" -ButtonRightText "OK" -Icon Information
    } else {
        Write-Log -Message "Failed to install $installName." -Source $deployAppScriptFriendlyName -Severity 3
        Show-InstallationPrompt -Message "Failed to install $installTitle. Please contact your administrator." -ButtonRightText "OK" -Icon Error
        Exit-Script -ExitCode 1603
    }
}

## Execute Deployment
Deploy-WinRAR

## Exit Script
Exit-Script -ExitCode 0