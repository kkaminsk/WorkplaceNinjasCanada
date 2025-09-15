# PowerShell script to remove CMTrace.exe from Windows folder
# Requires Administrator privileges

# Define log file path
$LogPath = "$env:SystemDrive\ProgramData\Microsoft\IntuneManagementExtension\Logs\CMTrace-v1.log"

# Function to write log entries in CMTrace format
function Write-CMTraceLog {
    param(
        [string]$Message,
        [string]$Component = "CMTrace-Remove",
        [ValidateSet("Info", "Warning", "Error")]
        [string]$Type = "Info"
    )
    
    $TimeStamp = Get-Date -Format "HH:mm:ss.fff"
    $Date = Get-Date -Format "MM-dd-yyyy"
    
    # Map type to CMTrace severity
    $Severity = switch ($Type) {
        "Info" { 1 }
        "Warning" { 2 }
        "Error" { 3 }
    }
    
    # CMTrace log format: <![LOG[Message]LOG]!><time="HH:mm:ss.fff+000" date="MM-dd-yyyy" component="Component" context="" type="Severity" thread="ThreadID" file="">
    $LogEntry = "<![LOG[$Message]LOG]!><time=`"$TimeStamp+000`" date=`"$Date`" component=`"$Component`" context=`"`" type=`"$Severity`" thread=`"$PID`" file=`"`">"
    
    # Ensure log directory exists
    $LogDir = Split-Path $LogPath -Parent
    if (-not (Test-Path $LogDir)) {
        New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
    }
    
    # Write to log file
    Add-Content -Path $LogPath -Value $LogEntry -Encoding UTF8
}

# Start logging
Write-CMTraceLog -Message "Starting CMTrace.exe removal operation" -Type "Info"

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-CMTraceLog -Message "Script requires Administrator privileges but is not running as Administrator" -Type "Error"
    Write-Error "This script requires Administrator privileges. Please run PowerShell as Administrator."
    exit 1
}

Write-CMTraceLog -Message "Administrator privileges confirmed" -Type "Info"

# Define target file path
$TargetPath = "$env:SystemRoot\CMTrace.exe"

# Check if target file exists
if (-not (Test-Path $TargetPath)) {
    Write-CMTraceLog -Message "CMTrace.exe not found at $TargetPath - nothing to remove" -Type "Warning"
    Write-Warning "CMTrace.exe not found at $TargetPath - nothing to remove"
    exit 0
}

Write-CMTraceLog -Message "Target file found: $TargetPath" -Type "Info"

# Get file information before deletion for logging
$fileInfo = Get-Item $TargetPath
$fileSize = $fileInfo.Length
$lastWriteTime = $fileInfo.LastWriteTime

Write-CMTraceLog -Message "File details - Size: $fileSize bytes, Last Modified: $lastWriteTime" -Type "Info"

try {
    Write-CMTraceLog -Message "Starting file removal operation for $TargetPath" -Type "Info"
    
    # Remove the file
    Remove-Item -Path $TargetPath -Force
    Write-CMTraceLog -Message "File removal operation completed successfully" -Type "Info"
    Write-Host "Successfully removed CMTrace.exe from $TargetPath" -ForegroundColor Green
    
    # Verify the removal was successful
    if (-not (Test-Path $TargetPath)) {
        Write-CMTraceLog -Message "Removal verification successful - file no longer exists" -Type "Info"
        Write-Host "Removal verification successful - CMTrace.exe is no longer in the Windows folder" -ForegroundColor Green
    } else {
        Write-CMTraceLog -Message "Removal operation appeared to succeed but file still exists" -Type "Error"
        Write-Error "Removal operation appeared to succeed but file still exists."
        exit 1
    }
}
catch {
    Write-CMTraceLog -Message "Failed to remove CMTrace.exe: $($_.Exception.Message)" -Type "Error"
    Write-Error "Failed to remove CMTrace.exe: $($_.Exception.Message)"
    exit 1
}

Write-CMTraceLog -Message "CMTrace.exe removal operation completed successfully. File has been removed from system" -Type "Info"
Write-Host "CMTrace.exe has been successfully removed from the Windows folder." -ForegroundColor Cyan
