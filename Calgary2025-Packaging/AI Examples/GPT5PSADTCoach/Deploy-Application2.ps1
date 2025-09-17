<#  PSAppDeployToolkit v4 – WinRAR 7.13 (x64)  Silent Package  #>

[CmdletBinding()]
param(
    [ValidateSet('Install','Uninstall','Repair')]
    [string]$DeploymentType = 'Install',
    [ValidateSet('Silent','Interactive','NonInteractive','Auto')]
    [string]$DeployMode = 'Silent',
    [switch]$DisableLogging,
    [switch]$SuppressRebootPassThru
)

# --- Session variables (v4 style) ---
$adtSession = @{
    AppVendor           = 'win.rar GmbH'
    AppName             = 'WinRAR'
    AppVersion          = '7.13'
    AppArch             = 'x64'
    AppLang             = 'EN'
    AppRevision         = '01'
    AppSuccessExitCodes = @(0)
    AppRebootExitCodes  = @(1641,3010)
    RequireAdmin        = $true
    AppProcessesToClose = @(
        @{ Name = 'winrar'; Description = 'WinRAR' },
        @{ Name = 'rar';    Description = 'RAR CLI' },
        @{ Name = 'unrar';  Description = 'UnRAR CLI' }
    )

    # Your house style – set these explicitly
    InstallName         = 'WinRAR_7.13_EN_x64_01'
    InstallTitle        = 'WinRAR 7.13 (x64)'

    # Internal
    DeploymentType      = $DeploymentType
    DeployMode          = $DeployMode
    DisableLogging      = [bool]$DisableLogging
    SuppressRebootPassThru = [bool]$SuppressRebootPassThru
}

# Open the toolkit session
try {
    $adtSession = Open-ADTSession @adtSession -PassThru
} catch {
    $Host.UI.WriteErrorLine($_ | Out-String)
    exit 60008
}

# Convenient paths
$PackageRoot     = Split-Path -Parent $MyInvocation.MyCommand.Path
$FilesDir        = Join-Path $PackageRoot 'Files'
$SupportFilesDir = Join-Path $PackageRoot 'SupportFiles'

function Get-WinRARInstaller {
    # Prefer x64, fall back if needed
    $candidates = @(
        Get-ChildItem -Path $FilesDir -Filter 'winrar*x64*.exe' -ErrorAction SilentlyContinue,
        Get-ChildItem -Path $FilesDir -Filter 'winrar*.exe'    -ErrorAction SilentlyContinue,
        Get-ChildItem -Path $FilesDir -Filter 'wrar*.exe'      -ErrorAction SilentlyContinue
    ) | Where-Object { $_ } | Select-Object -Unique
    if (-not $candidates) { throw "WinRAR installer EXE not found in $FilesDir." }
    return $candidates | Select-Object -First 1
}

function Install-ADTDeployment {
    [CmdletBinding()] param()

    # Pre-Install
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"
    # In Silent mode the UI is suppressed; still safe to define close-apps if needed.
    if ($adtSession.AppProcessesToClose.Count -gt 0) {
        Show-ADTInstallationWelcome -CloseProcesses $adtSession.AppProcessesToClose -AllowDeferCloseProcesses:$false -PersistPrompt:$false
    }
    Show-ADTInstallationProgress

    # Install
    $adtSession.InstallPhase = $adtSession.DeploymentType
    $installer = Get-WinRARInstaller
    Write-ADTLogEntry "Using installer: $($installer.Name)"

    # Primary silent switch: /S (uppercase). Fallback to -s if not detected after run.
    $proc = Start-ADTProcess -FilePath $installer.FullName -ArgumentList '/S' -PassThru
    Write-ADTLogEntry "Installer returned ExitCode $($proc.ExitCode). Checking detection..."

    Start-Sleep -Seconds 2
    $installed = Get-ADTApplication -FilterScript { $_.Publisher -match 'win.?rar' -and $_.DisplayName -match '^WinRAR' }

    if (-not $installed) {
        Write-ADTLogEntry "WinRAR not detected after /S. Retrying with -s (legacy silent)."
        Start-ADTProcess -FilePath $installer.FullName -ArgumentList '-s'
    }

    # License (optional): copy rarreg.key if present
    $key = @(
        Join-Path $SupportFilesDir 'rarreg.key',
        Join-Path $FilesDir        'rarreg.key'
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1

    if ($key) {
        $dest = Join-Path ${env:ProgramFiles} 'WinRAR\rarreg.key'
        Copy-ADTFile -Path $key -Destination $dest -Force
        Write-ADTLogEntry "Copied license key to $dest"
    }

    # Post-Install
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"
    Show-ADTInstallationPrompt -Message "WinRAR installation complete." -NoIcon -Timeout 2 -NotTopMost
}

function Uninstall-ADTDeployment {
    [CmdletBinding()] param()

    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"
    Show-ADTInstallationProgress

    $adtSession.InstallPhase = $adtSession.DeploymentType

    # Uninstall via the registered Uninstall string (EXE) with a silent switch
    Uninstall-ADTApplication -FilterScript { $_.DisplayName -match '^WinRAR' -and $_.Publisher -match 'win.?rar' } `
                             -ApplicationType EXE `
                             -ArgumentList '/S'

    # Safety: try both default locations if direct detection fails
    foreach ($path in @("${env:ProgramFiles}\WinRAR\uninstall.exe","${env:ProgramFiles(x86)}\WinRAR\uninstall.exe")) {
        if (Test-Path $path) {
            Start-ADTProcess -FilePath $path -ArgumentList '/S' -IgnoreExitCodes '*'
        }
    }

    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"
}

function Repair-ADTDeployment {
    [CmdletBinding()] param()
    # Simple repair = reinstall silently
    Install-ADTDeployment
}

# Kick off the selected deployment type
switch ($adtSession.DeploymentType) {
    'Install'   { Install-ADTDeployment }
    'Uninstall' { Uninstall-ADTDeployment }
    'Repair'    { Repair-ADTDeployment }
}

# Close the session
Close-ADTSession
