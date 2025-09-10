# WinRAR PowerShell App Deployment Toolkit (PSADT) Package

This package contains PowerShell scripts for deploying WinRAR using the PowerShell App Deployment Toolkit (PSADT).

## Files Included

- `Deploy-Application.ps1` - Main deployment script
- `AppDeployToolkitConfig.xml` - Configuration file for PSADT
- `README.md` - This documentation file

## Prerequisites

1. **PowerShell App Deployment Toolkit (PSADT)** - Download from [psappdeploytoolkit.com](http://psappdeploytoolkit.com)
2. **WinRAR Installer** - Download the appropriate version from [rarlab.com](https://www.rarlab.com)

## Setup Instructions

### 1. Download and Extract PSADT
1. Download the latest PSADT from the official website
2. Extract the toolkit to your deployment folder
3. Copy the `AppDeployToolkit` folder to the same directory as `Deploy-Application.ps1`

### 2. Prepare WinRAR Installer
1. Download the WinRAR installer (e.g., `winrar-x64-624.exe`)
2. Create a `Files` subdirectory in the same location as `Deploy-Application.ps1`
3. Place the WinRAR installer in the `Files` directory

### 3. Final Directory Structure
```
Claude/
├── Deploy-Application.ps1
├── AppDeployToolkitConfig.xml
├── README.md
├── AppDeployToolkit/
│   ├── AppDeployToolkitMain.ps1
│   ├── AppDeployToolkitExtensions.ps1
│   └── (other PSADT files)
└── Files/
    └── winrar-x64-624.exe (or similar)
```

## Usage

### Interactive Installation
```powershell
PowerShell.exe -ExecutionPolicy Bypass -File "Deploy-Application.ps1" -DeploymentType "Install" -DeployMode "Interactive"
```

### Silent Installation
```powershell
PowerShell.exe -ExecutionPolicy Bypass -File "Deploy-Application.ps1" -DeploymentType "Install" -DeployMode "Silent"
```

### Uninstallation
```powershell
PowerShell.exe -ExecutionPolicy Bypass -File "Deploy-Application.ps1" -DeploymentType "Uninstall" -DeployMode "Silent"
```

### Non-Interactive Installation (for SCCM/Intune)
```powershell
PowerShell.exe -ExecutionPolicy Bypass -File "Deploy-Application.ps1" -DeploymentType "Install" -DeployMode "NonInteractive"
```

## Features

### Installation Process
- **Pre-Installation**: Closes running WinRAR processes, removes existing installations
- **Installation**: Silently installs WinRAR from the Files directory
- **Post-Installation**: Verifies installation, creates desktop shortcut

### Uninstallation Process
- **Pre-Uninstallation**: Closes running WinRAR processes
- **Uninstallation**: Removes WinRAR using built-in uninstaller
- **Post-Uninstallation**: Cleans up shortcuts and remaining files

### Deployment Modes
- **Interactive**: Shows user dialogs and progress
- **Silent**: No user interaction, shows progress
- **NonInteractive**: Completely silent, suitable for automated deployment

## Configuration

### Application Variables
The script includes these configurable variables in the `Deploy-Application.ps1` file:

```powershell
[string]$appVendor = 'RARLAB'
[string]$appName = 'WinRAR'
[string]$appVersion = '6.24'
[string]$appArch = 'x64'
[string]$appLang = 'EN'
```

Update these variables to match your WinRAR version and requirements.

### Logging
- Logs are created automatically by PSADT
- Default location: `%WINDIR%\Logs\Software`
- Log format: CMTrace compatible

## SCCM/Intune Deployment

### SCCM Application
1. Create new Application in SCCM
2. Set Installation Program: `PowerShell.exe -ExecutionPolicy Bypass -File "Deploy-Application.ps1" -DeploymentType "Install" -DeployMode "NonInteractive"`
3. Set Uninstall Program: `PowerShell.exe -ExecutionPolicy Bypass -File "Deploy-Application.ps1" -DeploymentType "Uninstall" -DeployMode "NonInteractive"`
4. Configure detection method to check for WinRAR installation

### Intune Win32 App
1. Package the entire folder using Microsoft Win32 Content Prep Tool
2. Upload to Intune as Win32 app
3. Use the same command lines as SCCM
4. Configure requirements and detection rules

## Troubleshooting

### Common Issues
1. **Execution Policy**: Ensure PowerShell execution policy allows script execution
2. **Missing PSADT**: Verify AppDeployToolkit folder is present and contains required files
3. **Missing Installer**: Ensure WinRAR installer is in the Files directory
4. **Permissions**: Run with administrative privileges for system-wide installation

### Exit Codes
- **0**: Success
- **60008**: PSADT module failed to load
- **60001**: General script error
- **3010**: Success, restart required

## Version History

- **1.0.0** (2024-01-01): Initial version
  - Silent installation and uninstallation
  - Support for all PSADT deployment modes
  - Automatic cleanup of existing installations

## Support

For issues with:
- **PSADT**: Visit [psappdeploytoolkit.com](http://psappdeploytoolkit.com)
- **WinRAR**: Visit [rarlab.com](https://www.rarlab.com)
- **This Script**: Check the PowerShell execution logs for detailed error information
