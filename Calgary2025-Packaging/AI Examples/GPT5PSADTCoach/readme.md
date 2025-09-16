Awesome—I've dropped a ready-to-run **PSADT v4 package script for WinRAR 7.13 (x64)** into the canvas: **“Invoke-AppDeployToolkitWinRAR.ps1 (PSADT v4 package)”**. It’s wired for a fully silent install/uninstall, optional licensing, and a couple of sensible post-install cleanups.

### Finish the package (quick steps)

1. **Grab the current WinRAR (x64) 7.13 installer** and put it in your package’s `.\Files\` as `winrar-x64-713.exe`. As of today (Sep 16, 2025) 7.13 is the latest (released Jul 30, 2025). [rarlab.com+1](https://www.rarlab.com/download.htm?utm_source=chatgpt.com)
2. **(Optional) License:** drop your **`rarreg.key`** in `.\SupportFiles\`. The script will copy it into `C:\Program Files\WinRAR\` post-install, which is the standard location WinRAR reads from (installer can also auto-apply it if it sits next to the EXE). [techshelps.github.io](https://techshelps.github.io/WinRAR/html/HELPRegistering.htm?utm_source=chatgpt.com)
3. **(Optional) Default settings:** if you have a **`WinRAR.ini`**, place it in `.\SupportFiles\`. The script will copy it to `C:\Program Files\WinRAR\` so your preconfigured settings apply. (WinRAR supports INI-based config in the program folder or `%APPDATA%\WinRAR`.) [techshelps.github.io](https://techshelps.github.io/WinRAR/html/HELPWinRARIni.htm?utm_source=chatgpt.com)
4. **Run it silently:**

```
Invoke-AppDeployToolkit.exe -DeploymentType Install   -DeployMode Silent
```

Uninstall silently:

```
Invoke-AppDeployToolkit.exe -DeploymentType Uninstall -DeployMode Silent
```

### Notes baked into the script

- Uses the **official silent switch `-s`** for WinRAR’s installer. (WinRAR’s docs explicitly call out `-s` for silent.) [Documentation Help](https://documentation.help/WinRAR/HELPHints.htm?utm_source=chatgpt.com)
- If the exact `winrar-x64-713.exe` isn’t found, it will fall back to the newest `winrar-*.exe` in `Files\`.
- Removes common desktop/start menu shortcuts if they appear.
- Uninstall calls the product’s **`uninstall.exe -s`** when needed for a quiet removal. [Server Fault](https://serverfault.com/questions/830017/uninstall-winrar-through-gpo?utm_source=chatgpt.com)

### Why 7.13 right now?

WinRAR **7.13** includes fixes for a **recently exploited vulnerability (CVE-2025-8088)**; upgrading to 7.13 is recommended. [TechRadar+2Tom's Hardware+2](https://www.techradar.com/pro/security/winrar-has-a-serious-security-flaw-worrying-zero-day-issue-lets-hackers-plant-malware-so-patch-right-away?utm_source=chatgpt.com)

If you want me to pin language-specific builds, add detection logic for your environment, or bundle user-profile INI defaults, say the word and I’ll tweak the package.