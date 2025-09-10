# WinRAR Deployment (PSAppDeployToolkit)

This example installs WinRAR using the PowerShell App Deployment Toolkit (PSADT).

## Structure
- `AppDeployToolkit/` – Auto-populated on first run (downloaded from GitHub if missing).
- `Files/` – Place the WinRAR installer here (see below).
- `Logs/` – Logs directory.
- `Deploy-WinRAR.ps1` – Main deployment script.

## Requirements
- PowerShell 5.1+
- Internet access on first run (to download PSADT automatically), or pre-populate the `AppDeployToolkit/` folder.

## Installer Placement
Place the WinRAR installer at:
```
AI Examples/GPT5/Files/WinRAR-x64-624.exe
```

## Usage
Run PowerShell as Administrator and execute:
```
& "AI Examples/GPT5/Deploy-WinRAR.ps1"
```

The script will:
- Ensure `AppDeployToolkit/AppDeployToolkitMain.ps1` is available (download if needed).
- Perform a silent install of WinRAR (`/S`).
- Show basic PSADT UI prompts and logging.

## Notes
- Adjust the installer file name or parameters inside `Deploy-WinRAR.ps1` if you use another WinRAR build.
- This is a simplified example intended for lab/demo usage.
