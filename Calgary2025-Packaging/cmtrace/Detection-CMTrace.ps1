# CMTrace Detection Script for Intune Win32 App
# This script checks if CMTrace.exe is properly installed in the Windows folder
# Exit code 0 = Application is installed (detected)
# Exit code 1 = Application is not installed (not detected)

# Define the expected installation path
$CMTracePath = "$env:SystemRoot\CMTrace.exe"

# Check if CMTrace.exe exists
if (Test-Path $CMTracePath) {
    # File exists, now verify it's a valid executable
    try {
        $fileInfo = Get-Item $CMTracePath -ErrorAction Stop
        
        # Check if it's actually a file (not a directory)
        if ($fileInfo.PSIsContainer) {
            Write-Output "CMTrace.exe path exists but is a directory, not a file"
            exit 1
        }
        
        # Check file size (CMTrace.exe should be > 0 bytes)
        if ($fileInfo.Length -eq 0) {
            Write-Output "CMTrace.exe exists but has 0 bytes"
            exit 1
        }
        
        # Check if it's an executable file
        if ($fileInfo.Extension -ne ".exe") {
            Write-Output "CMTrace file exists but is not an .exe file"
            exit 1
        }
        
        # Optional: Check file version or other properties
        try {
            $versionInfo = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($CMTracePath)
            if ($versionInfo.FileDescription -like "*CMTrace*" -or $versionInfo.ProductName -like "*CMTrace*") {
                Write-Output "CMTrace.exe detected and verified - File Description: $($versionInfo.FileDescription)"
                exit 0
            } else {
                # Even if version info doesn't match, if it's a valid exe file, consider it installed
                Write-Output "CMTrace.exe detected at $CMTracePath (Size: $($fileInfo.Length) bytes)"
                exit 0
            }
        } catch {
            # If we can't get version info but file exists and is valid exe, still consider it installed
            Write-Output "CMTrace.exe detected at $CMTracePath (Size: $($fileInfo.Length) bytes)"
            exit 0
        }
        
    } catch {
        Write-Output "Error accessing CMTrace.exe: $($_.Exception.Message)"
        exit 1
    }
} else {
    Write-Output "CMTrace.exe not found at $CMTracePath"
    exit 1
}
