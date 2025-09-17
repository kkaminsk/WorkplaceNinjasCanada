<#
.SYNOPSIS
  PSAppDeployToolkit v4 package – WinRAR 7.13 (x64) silent install/uninstall.

.DESCRIPTION
  Drop this file into a PSADT v4 package folder alongside the toolkit (Invoke-AppDeployToolkit.exe/psd1).
  Place the WinRAR installer in .\Files and optional license/config in .\SupportFiles.

  Required:
    - Files\winrar-x64-713.exe   (official WinRAR 7.13 x64 installer)

  Optional (auto‑applied if present):
    - SupportFiles\rarreg.key    (WinRAR license key – will be copied to Program Files\WinRAR)
    - SupportFiles\WinRAR.ini    (preconfigured settings – will be copied to Program Files\WinRAR)

  Run examples:
    Invoke-AppDeployToolkit.exe -DeploymentType Install   -DeployMode Silent
    Invoke-AppDeployToolkit.exe -DeploymentType Uninstall -DeployMode Silent

.NOTES
  Author:  PSADT Coach
  Version: 1.0
  Tested : PSAppDeployToolkit 4.1.x
#>

[CmdletBinding()]
param(
    [ValidateSet('Install','Uninstall','Repair')]
    [string]$DeploymentType = 'Install',

    [ValidateSet('Auto','Silent','Interactive','NonInteractive')]
    [string]$DeployMode = 'Silent',

    [switch]$SuppressRebootPassThru,
    [switch]$TerminalServerMode,
    [switch]$DisableLogging
)

# =============================
# App/session metadata
# =============================
$adtSession = @{
    # App variables
    AppVendor            = 'win.rar GmbH'
    AppName              = 'WinRAR'
    AppVersion           = '7.13'
    AppArch              = 'x64'
    AppLang              = 'EN'
    AppRevision          = '01'
    AppSuccessExitCodes  = @(0)
    AppRebootExitCodes   = @(1641,3010)
    AppProcessesToClose  = @(@{ Name = 'winrar'; Description = 'WinRAR GUI' })
    AppScriptVersion     = '1.0.0'
    AppScriptDate        = (Get-Date -Format 'yyyy-MM-dd')
    AppScriptAuthor      = 'PSAppDeployToolkit'

    # Titles (override toolkit defaults if you want branded dialogs; no dialogs in Silent mode)
    InstallName          = 'WinRAR'
    InstallTitle         = 'WinRAR'

    # Script plumbing
    DeployAppScriptFriendlyName = $MyInvocation.MyCommand.Name
    DeployAppScriptParameters   = $PSBoundParameters
    DeployAppScriptVersion      = '4.1.5'
}

# =============================
# Load PSAppDeployToolkit core & open a session
# =============================
try {
    if (Test-Path -LiteralPath "$PSScriptRoot\PSAppDeployToolkit\PSAppDeployToolkit.psd1" -PathType Leaf) {
        Get-ChildItem -LiteralPath "$PSScriptRoot\PSAppDeployToolkit" -Recurse -File | Unblock-File -ErrorAction Ignore
        Import-Module -FullyQualifiedName @{ ModuleName = "$PSScriptRoot\PSAppDeployToolkit\PSAppDeployToolkit.psd1" } -Force
    }
    else {
        Import-Module -Name PSAppDeployToolkit -Force
    }

    $iadtParams = Get-ADTBoundParametersAndDefaultValues -Invocation $MyInvocation
    $adtSession = Open-ADTSession @adtSession @iadtParams -PassThru
}
catch {
    $Host.UI.WriteErrorLine((Out-String -InputObject $_ -Width ([int]::MaxValue)))
    exit 60008
}

# =============================
# INSTALL
# =============================
function Install-ADTDeployment {
    [CmdletBinding()]
    param()

    # ---------- Pre-Install ----------
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"

    # Optionally close WinRAR if running (has no service; just the GUI)
    if ($adtSession.AppProcessesToClose) {
        Close-ADTProcesses -Processes $adtSession.AppProcessesToClose -ContinueOnError
    }

    # ---------- Install ----------
    $adtSession.InstallPhase = $adtSession.DeploymentType

    # Resolve installer file. Prefer the exact versioned name, else fall back to the newest winrar*.exe in Files.
    $shortVer      = $adtSession.AppVersion -replace '\.',''
    $expectedName  = "winrar-$($adtSession.AppArch.ToLower())-$shortVer.exe"
    $candidatePath = Join-Path $adtSession.DirFiles $expectedName
    if (-not (Test-Path -LiteralPath $candidatePath)) {
        $found = Get-ChildItem -LiteralPath $adtSession.DirFiles -Filter 'winrar-*.exe' -ErrorAction Ignore | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($found) { $candidatePath = $found.FullName }
    }

    if (-not (Test-Path -LiteralPath $candidatePath)) {
        throw "WinRAR installer not found in [$($adtSession.DirFiles)]. Expected at least [$expectedName]."
    }

    # Silent install – official switch is -s (hyphen s)
    Start-ADTProcess -FilePath $candidatePath -ArgumentList '-s' -PassThru | Out-Null

    # ---------- Post-Install ----------
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"

    # Apply optional license (rarreg.key) if provided
    $license = Join-Path $adtSession.DirSupportFiles 'rarreg.key'
    if (Test-Path -LiteralPath $license) {
        New-ADTFolder -Path "$envProgramFiles\WinRAR" -ContinueOnError
        Copy-ADTFile -Path $license -Destination "$envProgramFiles\WinRAR\rarreg.key" -Force -ContinueOnError
    }

    # Apply optional global settings (WinRAR.ini) if provided
    $ini = Join-Path $adtSession.DirSupportFiles 'WinRAR.ini'
    if (Test-Path -LiteralPath $ini) {
        Copy-ADTFile -Path $ini -Destination "$envProgramFiles\WinRAR\WinRAR.ini" -Force -ContinueOnError
    }

    # Tidy common shortcuts (installer may create desktop/start menu icons)
    Remove-ADTFile -Path "$envCommonDesktop\WinRAR.lnk","$envCommonStartMenuPrograms\WinRAR\WinRAR.lnk" -ContinueOnError

    # Optional: verify installation by checking WinRAR.exe exists
    if (-not (Test-Path -LiteralPath "$envProgramFiles\WinRAR\WinRAR.exe")) {
        Write-ADTLogEntry -Severity 2 -Message 'WinRAR.exe not found after installation.'
    }
}

# =============================
# UNINSTALL
# =============================
function Uninstall-ADTDeployment {
    [CmdletBinding()]
    param()

    # ---------- Pre-Uninstall ----------
    $adtSession.InstallPhase = "Pre-$($adtSession.DeploymentType)"
    if ($adtSession.AppProcessesToClose) { Close-ADTProcesses -Processes $adtSession.AppProcessesToClose -ContinueOnError }

    # ---------- Uninstall ----------
    $adtSession.InstallPhase = $adtSession.DeploymentType

    # Use toolkit helper to run the product's uninstaller silently (appends our -s if needed)
    Uninstall-ADTApplication -Name 'WinRAR' -NameMatch 'Like' -ArgumentList '-s' -ContinueOnError

    # Fallback: run uninstall.exe silently from common locations if uninstall entry is missing
    $fallbacks = @(
        "$envProgramFiles\WinRAR\uninstall.exe",
        "$envProgramFiles(x86)\WinRAR\uninstall.exe"
    )
    foreach ($u in $fallbacks) {
        if (Test-Path -LiteralPath $u) {
            Start-ADTProcess -FilePath $u -ArgumentList '-s' -PassThru -ContinueOnError | Out-Null
        }
    }

    # ---------- Post-Uninstall ----------
    $adtSession.InstallPhase = "Post-$($adtSession.DeploymentType)"
    Remove-ADTFile -Path "$envProgramFiles\WinRAR","$envProgramFiles(x86)\WinRAR" -Recurse -ContinueOnError
}

# =============================
# REPAIR (re-run installer silently)
# =============================
function Repair-ADTDeployment {
    [CmdletBinding()] param()
    Install-ADTDeployment
}

# =============================
# Invoke
# =============================
try {
    switch ($adtSession.DeploymentType) {
        'Install'   { Install-ADTDeployment }
        'Uninstall' { Uninstall-ADTDeployment }
        'Repair'    { Repair-ADTDeployment }
    }

    Close-ADTSession -ExitCode 0 -DisableLogging:$DisableLogging -SuppressRebootPassThru:$SuppressRebootPassThru
}
catch {
    $err = "An unhandled error occurred in [$($MyInvocation.MyCommand.Name)]:`n$(Resolve-ADTErrorRecord -ErrorRecord $_)"
    Write-ADTLogEntry -Message $err -Severity 3
    Show-ADTInstallationPrompt -Message "$($adtSession.DeploymentType) failed for $($adtSession.AppName)." -MessageAlignment Left -Icon Error -ButtonRightText OK -NoWait
    Close-ADTSession -ExitCode 60001
}
