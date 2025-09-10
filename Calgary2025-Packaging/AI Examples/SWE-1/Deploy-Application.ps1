<#
.SYNOPSIS
    Installs WinRAR using PowerShell App Deployment Toolkit.
.DESCRIPTION
    This script installs WinRAR silently using the PowerShell App Deployment Toolkit.
    It includes logging, error handling, and proper exit codes.
.NOTES
    FileName:    Deploy-Application.ps1
    Author:      Workplace Ninjas Canada
    Contact:     admin@workplaceninjas.ca
    Version:     1.0.0
    Created:     2024-09-10
#>

##*===============================================
##* VARIABLE DECLARATION
##*===============================================
## Variables: Application
[string]$appVendor = 'RARLAB'
[string]$appName = 'WinRAR'
[string]$appVersion = '6.24'
[string]$appArch = 'x64'
[string]$appLang = 'EN'
[string]$appRevision = '01'
[string]$appScriptVersion = '1.0.0'
[string]$appScriptDate = '09/10/2024'
[boolean]$is64Bit = $true

##*===============================================
##* VARIABLE DECLARATION - DO NOT MODIFY BELOW
##*===============================================
## Variables: Installer
[string]$installerName = 'WinRAR-$appArch-$appVersion.exe'
[string]$installerFile = "$dirFiles\$installerName"
[string]$installParameters = "/S"

##*===============================================
##* INSTALLATION
##*===============================================
[ScriptBlock]$install = {
    
    Show-InstallationWelcome -CloseApps "winrar,winrar64" -CloseAppsCountdown 60
    
    # Check if WinRAR is already installed
    $installedVersion = Get-InstalledApplication -Name "WinRAR*" | Select-Object -ExpandProperty DisplayVersion -First 1
    
    if ($installedVersion) {
        Write-Log -Message "WinRAR version $installedVersion is already installed. Checking if update is needed..." -Source $deployAppScriptFriendlyName
        
        # Convert version strings to System.Version objects for comparison
        $installedVer = [version]$installedVersion
        $newVer = [version]$appVersion
        
        if ($installedVer -ge $newVer) {
            Write-Log -Message "Installed version ($installedVersion) is the same or newer than the package version ($appVersion). No update needed." -Source $deployAppScriptFriendlyName
            Show-InstallationPrompt -Message "WinRAR $installedVersion is already installed and up to date." -ButtonRightText 'OK' -Icon Information -NoWait
            Exit-Script -ExitCode 0
        }
        else {
            Write-Log -Message "Upgrading WinRAR from version $installedVersion to $appVersion" -Source $deployAppScriptFriendlyName
            $installParameters += " /U"
        }
    }
    
    # Execute the installer
    $exitCode = Execute-Process -Path $installerFile -Parameters $installParameters -WindowStyle Hidden -PassThru
    
    # Verify installation
    $installSuccess = $false
    if (Test-Path -Path "${env:ProgramFiles}\WinRAR\WinRAR.exe") {
        $installSuccess = $true
    }
    
    if ($installSuccess) {
        Write-Log -Message "Successfully installed $appName $appVersion" -Source $deployAppScriptFriendlyName
        Show-InstallationPrompt -Message "$appName $appVersion has been successfully installed." -ButtonRightText 'OK' -Icon Information -NoWait
    }
    else {
        Write-Log -Message "Failed to install $appName $appVersion. Exit code: $exitCode" -Source $deployAppScriptFriendlyName -Severity 3
        Throw "Failed to install $appName $appVersion. Exit code: $exitCode"
    }
}

##*===============================================
##* UNINSTALLATION
##*===============================================
[ScriptBlock]$uninstall = {
    Show-InstallationWelcome -CloseApps "winrar,winrar64" -CloseAppsCountdown 60
    
    # Uninstall WinRAR
    $uninstallString = Get-InstalledApplication -Name "WinRAR*" | Select-Object -ExpandProperty UninstallString -First 1
    
    if ($uninstallString) {
        $uninstallString = $uninstallString -replace '"', ''
        $uninstallPath = Split-Path -Path $uninstallString -Parent
        $uninstallExe = Join-Path -Path $uninstallPath -ChildPath "Uninstall.exe"
        
        if (Test-Path -Path $uninstallExe) {
            $exitCode = Execute-Process -Path $uninstallExe -Parameters "/S" -WindowStyle Hidden -PassThru
            
            if ($exitCode -eq 0) {
                Write-Log -Message "Successfully uninstalled $appName" -Source $deployAppScriptFriendlyName
            }
            else {
                Write-Log -Message "Failed to uninstall $appName. Exit code: $exitCode" -Source $deployAppScriptFriendlyName -Severity 3
                Throw "Failed to uninstall $appName. Exit code: $exitCode"
            }
        }
    }
    else {
        Write-Log -Message "$appName is not installed." -Source $deployAppScriptFriendlyName -Severity 2
    }
}

##*===============================================
##* MAIN LOGIC
##*===============================================
Try {
    ##* Run the installation if the deployment mode is not uninstall
    If ($deploymentType -ine 'uninstall') {
        & $install
    }
    
    ##* Run uninstallation if the deployment mode is uninstall
    If ($deploymentType -ieq 'uninstall') {
        & $uninstall
    }
    
    ##* Set the installation success/failure in the script exit code if an install or uninstall was performed
    If (-not $useDefaultMsi) {
        If ($deploymentType -ine 'uninstall') {
            If (Test-Path -Path "${env:ProgramFiles}\WinRAR\WinRAR.exe") {
                Exit-Script -ExitCode 0
            } Else {
                Exit-Script -ExitCode 1
            }
        } Else {
            If (-not (Test-Path -Path "${env:ProgramFiles}\WinRAR\WinRAR.exe" -ErrorAction SilentlyContinue)) {
                Exit-Script -ExitCode 0
            } Else {
                Exit-Script -ExitCode 1
            }
        }
    }
}
Catch {
    $exceptionMessage = $_.Exception.Message
    Write-Log -Message "Error: $exceptionMessage" -Source $deployAppScriptFriendlyName -Severity 3
    Show-InstallationPrompt -Message "An error occurred during installation: $exceptionMessage" -ButtonRightText 'OK' -Icon Error -NoWait
    Exit-Script -ExitCode 1
}
