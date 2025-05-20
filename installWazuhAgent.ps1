# Define variables
$wazuhUrl = "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.11.2-1.msi"
$installerPath = "$env:TEMP\wazuh-agent.msi"
$manager = "siem.goodfeetnw.com"
$regPassword = "qe9OBgA9dM%rHJS#"
$agentGroup = "Windows"

Write-Host "Downloading Wazuh agent installer..."
try {
    Invoke-WebRequest -Uri $wazuhUrl -OutFile $installerPath -UseBasicParsing
    Write-Host "Download complete."
} catch {
    Write-Error "Failed to download Wazuh agent installer: $_"
    exit 1
}

Write-Host "Installing Wazuh agent silently..."
try {
    Start-Process msiexec.exe -ArgumentList "/i `"$installerPath`" /qn WAZUH_MANAGER='$manager' WAZUH_REGISTRATION_PASSWORD='$regPassword' WAZUH_AGENT_GROUP='$agentGroup'" -Wait
    Write-Host "Installation completed."
} catch {
    Write-Error "Installation failed: $_"
    exit 1
}

Write-Host "Starting Wazuh Agent service..."
Start-Service -Name "WazuhSvc"

# Confirm service status
$service = Get-Service -Name "WazuhSvc"
if ($service.Status -eq "Running") {
    Write-Host "✅ Wazuh Agent service is running."
} else {
    Write-Warning "⚠️ Wazuh Agent service is not running. Current status: $($service.Status)"
}
