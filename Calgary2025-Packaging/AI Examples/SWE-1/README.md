# WinRAR Deployment Package

This package contains the necessary files and scripts to deploy WinRAR using the PowerShell App Deployment Toolkit (PSAppDeployToolkit).

## Prerequisites

- PowerShell 5.1 or later
- Administrative privileges on the target machine
- PowerShell Execution Policy set to allow script execution (RemoteSigned or Unrestricted)

## Files

- `Deploy-Application.ps1` - Main deployment script
- `Files\` - Directory containing the WinRAR installer
- `AppDeployToolkit\` - PowerShell App Deployment Toolkit files

## Usage

### Installation

1. Download the WinRAR installer and place it in the `Files` directory with the name `WinRAR-x64-6.24.exe`
2. Run the deployment script with administrative privileges:
   ```powershell
   .\Deploy-Application.ps1 -DeploymentType "Install" -DeployMode "Silent"
   ```

### Uninstallation

To uninstall WinRAR, run:

```powershell
.\Deploy-Application.ps1 -DeploymentType "Uninstall" -DeployMode "Silent"
```

### Parameters

- `-DeploymentType`: The type of deployment to perform (Install, Uninstall, or Repair)
- `-DeployMode`: The deployment mode (Interactive, Silent, or NonInteractive)
- `-AllowRebootPassThru`: Allow the script to reboot the computer if needed
- `-TerminalServerMode`: Set to install in Terminal Server mode

## Logging

Logs are stored in the `Logs` directory with the format `Log-{Date}-{Time}-{ProcessID}.log`

## Notes

- This package is configured for 64-bit Windows systems
- The installation is completely silent by default
- The script will automatically close any running instances of WinRAR during installation/uninstallation

## Version History

- 1.0.0 (2024-09-10): Initial release
