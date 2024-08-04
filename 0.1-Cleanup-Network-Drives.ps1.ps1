Install-Module -Name EnhancedBoilerPlateAO -Scope AllUsers -Force
Install-Module -Name EnhancedLoggingAO -Scope AllUsers -Force

Write-EnhancedLog "Logging works" -Level "INFO"

function Remove-AllNetworkDrives {
    # Get all PS drives that are mapped to a network path (DisplayRoot will be non-empty for network drives)
    $networkDrives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.DisplayRoot -like '\\*' }

    # Loop through each network drive and remove it
    foreach ($drive in $networkDrives) {
        try {
            # Using net use to ensure the drive is removed even if it was created outside of the current PowerShell session
            $result = net use "$($drive.Name):" /delete
            if ($result -match "successfully") {
                Write-Host "Successfully removed network drive $($drive.Name):"
            } else {
                Write-Warning "Could not remove network drive $($drive.Name):"
            }
        } catch {
            Write-Error "Error removing network drive $($drive.Name): $_"
        }
    }
}

Remove-AllNetworkDrives