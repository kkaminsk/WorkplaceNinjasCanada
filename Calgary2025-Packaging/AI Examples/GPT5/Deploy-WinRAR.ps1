#requires -version 5.1
<#+
.SYNOPSIS
    Installs WinRAR using the PowerShell App Deployment Toolkit (PSADT).

.DESCRIPTION
    This script will ensure the PSAppDeployToolkit framework is present in a local AppDeployToolkit/ folder
    (downloading the latest release if missing), then perform a silent install of WinRAR.

    Place the WinRAR installer in: .\Files\WinRAR-x64-624.exe

.NOTES
    Author: Cascade
    Date: 2025-09-10
#>

#region Helper: Resolve paths
$ScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$ToolkitDir = Join-Path $ScriptRoot 'AppDeployToolkit'
$ToolkitMain = Join-Path $ToolkitDir 'AppDeployToolkitMain.ps1'
$FilesDir   = Join-Path $ScriptRoot 'Files'
$LogsDir    = Join-Path $ScriptRoot 'Logs'

# Ensure folders exist
$newDirs = @($ToolkitDir, $FilesDir, $LogsDir)
foreach ($d in $newDirs) { if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null } }
# Start a transcript for detailed logging
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$TranscriptPath = Join-Path $LogsDir "Deploy-WinRAR_$timestamp.log"
try { Start-Transcript -Path $TranscriptPath -ErrorAction SilentlyContinue | Out-Null } catch {}
#endregion

#region Bootstrap PSAppDeployToolkit if missing
if (-not (Test-Path -LiteralPath $ToolkitMain)) {
    Write-Host 'PSAppDeployToolkit not found. Downloading latest release...' -ForegroundColor Yellow

    # Ensure modern TLS for GitHub downloads (common issue on legacy defaults)
    try {
        $sp = [Net.ServicePointManager]::SecurityProtocol
        $tls12 = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
        $tls13 = 12288 # not defined in older frameworks; safe to OR even if unsupported
        [Net.ServicePointManager]::SecurityProtocol = $sp -bor $tls12 -bor $tls13
    } catch {}

    $zipUrl = 'https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/releases/latest/download/PSAppDeployToolkit.zip'
    $zipPath = Join-Path $env:TEMP ("PSAppDeployToolkit_" + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.zip')

    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing -TimeoutSec 120
        Write-Host 'Download complete. Extracting...' -ForegroundColor Cyan

        $extractDir = Join-Path $env:TEMP ("PSADT_" + (Get-Date -Format 'yyyyMMdd_HHmmss'))
        Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force

        # The zip contains PSAppDeployToolkit\Toolkit\Files... and Toolkit root. Move the Toolkit root contents to our AppDeployToolkit folder.
        $possibleRoots = @(
            Join-Path $extractDir 'Toolkit',
            Join-Path $extractDir 'PSAppDeployToolkit',
            $extractDir
        )
        $srcRoot = $possibleRoots | Where-Object { Test-Path (Join-Path $_ 'AppDeployToolkitMain.ps1') } | Select-Object -First 1
        if (-not $srcRoot) { throw 'Could not locate AppDeployToolkitMain.ps1 inside the downloaded archive.' }

        if (-not (Test-Path -LiteralPath $ToolkitDir)) { New-Item -ItemType Directory -Path $ToolkitDir -Force | Out-Null }

        # Copy only the Toolkit root (AppDeployToolkit*)
        Get-ChildItem -LiteralPath $srcRoot -File | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $ToolkitDir -Force }
        Get-ChildItem -LiteralPath $srcRoot -Directory | ForEach-Object { Copy-Item -Recurse -LiteralPath $_.FullName -Destination $ToolkitDir -Force }

        Write-Host 'PSAppDeployToolkit extracted.' -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to download or extract PSAppDeployToolkit: $($_.Exception.Message)"
        exit 1
    }
    finally {
        if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force -ErrorAction SilentlyContinue }
    }
}
#endregion

#region Import PSADT
try {
    . $ToolkitMain
}
catch {
    Write-Error "Failed to load PSAppDeployToolkit: $($_.Exception.Message)"
    exit 1
}
#endregion

#region App Specific Variables
[string]$appName = 'WinRAR'
[string]$appVersion = '6.24'
[string]$installTitle = "$appName $appVersion"

# WinRAR installer expected location and silent parameters
$InstallerFileName = 'WinRAR-x64-624.exe'
$InstallerPath = Join-Path $FilesDir $InstallerFileName
$InstallerParams = '/S'
#endregion

#region Begin PSADT Install
Try {
    ## Show pre-install UI and close apps if needed (WinRAR usually has no running apps to close)
    Show-InstallationWelcome -CloseApps 'winrar' -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt
    Show-InstallationProgress -StatusMessage "Installing $installTitle..."

    ## Pre-req validation
    if (-not (Test-Path -LiteralPath $InstallerPath)) {
        Throw "Installer not found: $InstallerPath. Place $InstallerFileName in the Files/ folder."
    }

    ## Install
    Write-Log -Message "Starting install: $InstallerPath $InstallerParams" -Source 'Deploy-WinRAR'
    Execute-Process -Path $InstallerPath -Parameters $InstallerParams -WindowStyle Hidden -CreateNoWindow -PassThru | Out-Null

    ## Post-Install (optionally create shortcuts, etc.)
    # Example: Register-Application -DisplayName $appName -FileType 'rar' -IconPath 'C:\Program Files\WinRAR\WinRAR.exe'

    ## Installation complete
    Show-InstallationPrompt -Message "Installation complete: $installTitle" -ButtonRightText 'OK' -Icon Information -NoWait
}
Catch {
    Write-Log -Message ("Installation failed: " + $_.Exception.Message) -Severity 3 -Source 'Deploy-WinRAR'
    Show-InstallationPrompt -Message ("Installation failed: " + $_.Exception.Message) -ButtonRightText 'OK' -Icon Error
    Exit-Script -ExitCode 1
}
Finally {
    Close-InstallationProgress
    try { Stop-Transcript | Out-Null } catch {}
}

Exit-Script -ExitCode 0
