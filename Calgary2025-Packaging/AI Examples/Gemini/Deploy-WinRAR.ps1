<#
.SYNOPSIS
	This script performs the installation or uninstallation of WinRAR.
.DESCRIPTION
	The script is designed to be used with the PowerShell App Deployment Toolkit. 
	It can be used to install or uninstall WinRAR silently.
.EXAMPLE
	Deploy-WinRAR.ps1 -DeploymentType "Install"
.EXAMPLE
	Deploy-WinRAR.ps1 -DeploymentType "Uninstall"
#>

Try {
	## Set the script execution context
	Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force

	##*=============================================== 
	##* VARIABLE DECLARATION
	##*===============================================
	## Variables: Application
	[string]$appVendor = 'WinRAR'
	[string]$appName = 'WinRAR'
	[string]$appVersion = '6.24'
	[string]$appArch = 'x64'
	[string]$appLang = 'EN'
	[string]$appRevision = '1'
	[string]$appDeploymentType = 'Installation'
	[string]$appScriptVersion = '1.0.0'
	[string]$appScriptDate = '2025-09-10'
	[string]$appScriptAuthor = 'Cascade'

	##*=============================================== 
	##* END VARIABLE DECLARATION
	##*===============================================

	##*=============================================== 
	##* SCRIPT BODY
	##*===============================================
	## Get the name of the script file
	[string]$scriptName = $MyInvocation.MyCommand.Name

	## Get the script's immediate parent directory
	[string]$scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

	## Get the path to the AppDeployToolkitMain.ps1 script
	[string]$mainScript = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"

	## If the AppDeployToolkitMain.ps1 script exists, dot-source it
	if (Test-Path -Path $mainScript -PathType 'Leaf') {
		. $mainScript
	}
	else {
		Write-Error -Message "Failed to find AppDeployToolkitMain.ps1 at [$mainScript]. Please check that the script is located in the correct directory." -ErrorAction 'Stop'
	}

	##*=============================================== 
	##* PRE-INSTALLATION
	##*===============================================
	If ($deploymentType -ieq 'Install') {
		## Show Welcome Message, close applications, define progress message.
		Show-InstallationWelcome -CloseApps 'WinRAR'
		Show-InstallationProgress

		##*=============================================== 
		##* INSTALLATION
		##*===============================================
		## Install WinRAR
		Execute-Process -Path 'WinRAR-x64-624.exe' -Parameters '/S' -WindowStyle 'Hidden' -PassThru
	}

	##*=============================================== 
	##* POST-INSTALLATION
	##*===============================================
	If ($deploymentType -ieq 'Install') {
		## Display a message at the end of the installation
		Show-InstallationComplete -FinalMessage 'WinRAR has been installed successfully.'
	}

	##*=============================================== 
	##* UNINSTALLATION
	##*===============================================
	If ($deploymentType -ieq 'Uninstall') {
		## Show Welcome Message, close applications, define progress message.
		Show-UninstallationWelcome -CloseApps 'WinRAR'
		Show-UninstallationProgress

		## Uninstall WinRAR
		Execute-Process -Path 'C:\Program Files\WinRAR\Uninstall.exe' -Parameters '/S' -WindowStyle 'Hidden' -PassThru
	}

	##*=============================================== 
	##* POST-UNINSTALLATION
	##*===============================================
	If ($deploymentType -ieq 'Uninstall') {
		## Display a message at the end of the uninstallation
		Show-UninstallationComplete -FinalMessage 'WinRAR has been uninstalled successfully.'
	}

	##*=============================================== 
	##* END SCRIPT BODY
	##*===============================================

}
Catch {
	[int32]$mainExitCode = 60001
	Write-Error -Message "$_.Exception.Message" -ErrorAction 'Continue'
	Exit $mainExitCode
}
Finally {
	## Exit the script, returning the appropriate exit code to the parent process.
	Exit $mainExitCode
}
