<#
.SYNOPSIS
	This script installs, configures, or uninstalls Sysmon on a Windows system.

.DESCRIPTION
	The script provides functionality to download, install, and configure Sysmon, a system monitoring tool from Sysinternals. It also allows for the uninstallation of Sysmon. The script includes logging capabilities and checks to ensure Sysmon is running with the latest configuration.

.PARAMETER InstallSysmon
	Switch parameter to install and configure Sysmon.

.PARAMETER UninstallSysmon
	Switch parameter to uninstall Sysmon.

.EXAMPLE
	.\Install-Configure-Sysmon.ps1 -InstallSysmon
	Installs and configures Sysmon with the specified configuration.

.EXAMPLE
	.\Install-Configure-Sysmon.ps1 -UninstallSysmon
	Uninstalls Sysmon from the system.

.NOTES
	Author: Martin Bengtsson
	Date: 12-02-2025
	Version: 1.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
	[switch]$InstallSysmon,
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [switch]$UninstallSysmon
)

# Define URLs and paths
$sysmonUrl = "https://download.sysinternals.com/files/Sysmon.zip"
$sysmonConfigUrl = "https://raw.githubusercontent.com/olafhartong/sysmon-modular/refs/heads/master/sysmonconfig.xml"
$sysmonBasePath = "C:\Windows\Sysmon"
$sysmonZipPath = "C:\Windows\Temp\Sysmon.zip"
$sysmonExtractPath = $sysmonBasePath
$sysmonConfigPath = (Join-Path -Path $sysmonBasePath -ChildPath "sysmonconfig.xml")
$sysmonLogPath = (Join-Path -Path $sysmonBasePath -ChildPath "sysmon-install.log")
$sysmonConfigVersion = "75"
$sysmonConfigContent = ""

if (-not (Test-Path -Path $sysmonBasePath)) {
    New-Item -Path $sysmonBasePath -ItemType Directory -Force | Out-Null
}

# Logging function
function Write-Log {
	param ([string]$logMessage)
	$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
	$logMessage = "$timestamp - $logMessage"
	$logMessage | Out-File -FilePath $sysmonLogPath -Append -Encoding UTF8
	Write-Output $logMessage
}

function Test-SysmonService {
	try {
		$service = Get-Service -Name "Sysmon" -ErrorAction Stop
		if ($service.Status -eq 'Running') {
			Write-Log "Sysmon service is running."
			return $true
		} else {
			Write-Log "Sysmon service is not running."
			return $false
		}
	} catch {
		Write-Log "Sysmon service is not installed."
		return $false
	}
}

# Install function
function Install-Sysmon() {
	$sysmonService = Test-SysmonService
	if ($sysmonService -eq $true) {
		Write-Log "Sysmon already installed. Updating configuration..."
		try {
			Invoke-WebRequest -Uri $sysmonConfigUrl -OutFile $sysmonConfigPath -UseBasicParsing -ErrorAction Stop
			Start-Process -FilePath (Join-Path $sysmonExtractPath "Sysmon64.exe") -ArgumentList "-c $sysmonConfigPath" -NoNewWindow -Wait
			Write-Log "Sysmon configuration updated."
		} catch {
			Write-Log "Failed to update configuration: $_"
		}
	} else {
		try {
			Write-Log "Downloading Sysmon..."
			Invoke-WebRequest -Uri $sysmonUrl -OutFile $sysmonZipPath -UseBasicParsing -ErrorAction Stop

			Write-Log "Extracting Sysmon..."
			Expand-Archive -Path $sysmonZipPath -DestinationPath $sysmonExtractPath -Force -ErrorAction Stop

			Write-Log "Downloading Sysmon configuration..."
			Invoke-WebRequest -Uri $sysmonConfigUrl -OutFile $sysmonConfigPath -UseBasicParsing -ErrorAction Stop

			Write-Log "Installing Sysmon..."
			$sysmonExePath = (Join-Path -Path $sysmonExtractPath -ChildPath "Sysmon64.exe")
			Start-Process -FilePath $sysmonExePath -ArgumentList "-accepteula -i $sysmonConfigPath" -NoNewWindow -Wait

			if (Test-SysmonService) {
				Write-Log "Sysmon successfully installed."
			}
		} catch {
			Write-Log "Failed during installation: $_"
		}
	}
}

# Uninstall function
function Uninstall-Sysmon {
	try {
		Write-Log "Uninstalling Sysmon..."
		$sysmonExePath = (Join-Path -Path $sysmonExtractPath -ChildPath "Sysmon64.exe")
		Start-Process -FilePath $sysmonExePath -ArgumentList "-u" -NoNewWindow -Wait
		Write-Log "Sysmon successfully uninstalled."
	} catch {
		Write-Log "Failed to uninstall Sysmon: $_"
	}
}

# Execution logic
if ($PSBoundParameters["InstallSysmon"]) {
	Install-Sysmon
}
if ($PSBoundParameters["UninstallSysmon"]) {
	Uninstall-Sysmon
}
