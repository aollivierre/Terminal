function Add-HostsEntry {
    param(
        [string]$IPAddress,
        [string]$Hostname
    )

    $hostsPath = "C:\Windows\System32\drivers\etc\hosts"
    $entry = "$IPAddress`t$Hostname"

    # Check if the entry already exists
    $exists = Get-Content -Path $hostsPath | Select-String -Pattern "^\s*$IPAddress\s+$Hostname" -Quiet

    if (-not $exists) {
        # Add entry to the hosts file
        Add-Content -Path $hostsPath -Value $entry
        Write-Host "Entry '$entry' added to hosts file."
    } else {
        Write-Host "Entry '$entry' already exists in the hosts file."
    }
}


function Create-NetworkDrive {
    param(
        [string]$DriveLetter = "S:",
        [string]$NetworkPath = "\\path\to\network\share", # Update this to your network share path
        [string]$DriveName = "code"
    )

    # Check if the drive letter is already in use
    if (Test-Path $DriveLetter) {
        Write-Host "Drive letter '$DriveLetter' is already in use."
    } else {
        # Map the network drive
        $null = New-PSDrive -Name $DriveName -PSProvider FileSystem -Root $NetworkPath -Persist -Scope Global -ErrorAction Stop
        Write-Host "Network drive '$DriveName' mapped to '$DriveLetter' at '$NetworkPath'."
    }
}


# Update hosts file
Add-HostsEntry -IPAddress "192.168.100.230" -Hostname "NNOTT-LLW-SL08"

# Create network drive
Create-NetworkDrive -DriveLetter "S:" -NetworkPath "\\NNOTT-LLW-SL08\code" -DriveName "code"
