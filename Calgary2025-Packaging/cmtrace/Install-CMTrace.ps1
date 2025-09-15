# PowerShell script to copy CMTrace.exe to Windows folder
# Requires Administrator privileges

# Define log file path
$LogPath = "$env:SystemDrive\ProgramData\Microsoft\IntuneManagementExtension\Logs\CMTrace-v1.log"

# Function to write log entries in CMTrace format
function Write-CMTraceLog {
    param(
        [string]$Message,
        [string]$Component = "CMTrace-Copy",
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
Write-CMTraceLog -Message "Starting CMTrace.exe copy operation" -Type "Info"

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-CMTraceLog -Message "Script requires Administrator privileges but is not running as Administrator" -Type "Error"
    Write-Error "This script requires Administrator privileges. Please run PowerShell as Administrator."
    exit 1
}

Write-CMTraceLog -Message "Administrator privileges confirmed" -Type "Info"

# Define source and destination paths
$SourcePath = Join-Path $PSScriptRoot "CMTrace.exe"
$DestinationPath = "$env:SystemRoot\CMTrace.exe"

# Check if source file exists
if (-not (Test-Path $SourcePath)) {
    Write-CMTraceLog -Message "Source file not found: $SourcePath" -Type "Error"
    Write-Error "Source file not found: $SourcePath"
    exit 1
}

Write-CMTraceLog -Message "Source file found: $SourcePath" -Type "Info"

try {
    Write-CMTraceLog -Message "Starting file copy operation from $SourcePath to $DestinationPath" -Type "Info"
    
    # Copy the file
    Copy-Item -Path $SourcePath -Destination $DestinationPath -Force
    Write-CMTraceLog -Message "File copy operation completed successfully" -Type "Info"
    Write-Host "Successfully copied CMTrace.exe to $DestinationPath" -ForegroundColor Green
    
    # Verify the copy was successful
    if (Test-Path $DestinationPath) {
        Write-CMTraceLog -Message "Destination file exists, performing size verification" -Type "Info"
        $sourceSize = (Get-Item $SourcePath).Length
        $destSize = (Get-Item $DestinationPath).Length
        
        if ($sourceSize -eq $destSize) {
            Write-CMTraceLog -Message "File verification successful - sizes match ($sourceSize bytes)" -Type "Info"
            Write-Host "File verification successful - sizes match ($sourceSize bytes)" -ForegroundColor Green
        } else {
            Write-CMTraceLog -Message "File sizes don't match. Source: $sourceSize bytes, Destination: $destSize bytes" -Type "Warning"
            Write-Warning "File sizes don't match. Source: $sourceSize bytes, Destination: $destSize bytes"
        }
    } else {
        Write-CMTraceLog -Message "Copy operation appeared to succeed but destination file not found" -Type "Error"
        Write-Error "Copy operation appeared to succeed but destination file not found."
    }
}
catch {
    Write-CMTraceLog -Message "Failed to copy CMTrace.exe: $($_.Exception.Message)" -Type "Error"
    Write-Error "Failed to copy CMTrace.exe: $($_.Exception.Message)"
    exit 1
}

Write-CMTraceLog -Message "CMTrace.exe copy operation completed successfully. File is now available system-wide" -Type "Info"
Write-Host "CMTrace.exe is now available system-wide from the Windows folder." -ForegroundColor Cyan
