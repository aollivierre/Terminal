Install-Module -Name EnhancedBoilerPlateAO -Scope AllUsers -Force
Install-Module -Name EnhancedLoggingAO -Scope AllUsers -Force

Write-EnhancedLog "Logging works" -Level "INFO"

function Get-CredentialsFromJson {
    [CmdletBinding()]
    param (
        [string]$JsonPath
    )

    if (Test-Path $JsonPath) {
        try {
            $jsonContent = Get-Content -Path $JsonPath -Raw | ConvertFrom-Json
            $securePassword = ConvertTo-SecureString -String $jsonContent.password -AsPlainText -Force
            $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $jsonContent.username, $securePassword
            return $credential
        } catch {
            Write-Error "Failed to parse JSON content. Error: $_"
        }
    } else {
        Write-Error "JSON file not found at path: $JsonPath"
    }
}

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


function Get-MappedNetworkDrives {
    [CmdletBinding()]
    param (
        [string]$CheckDriveLetter
    )
    
    $mappedDrives = Get-PSDrive -PSProvider 'FileSystem' | Where-Object {
        $_.DisplayRoot -like '\\*'
    }

    if ($mappedDrives) {
        Write-Host "Current mapped network drives:"
        foreach ($drive in $mappedDrives) {
            Write-Host "Drive Letter: $($drive.Name) - Network Path: $($drive.DisplayRoot)"
        }
    } else {
        Write-Host "No network drives are currently mapped."
    }

    if ($CheckDriveLetter) {
        $checkResult = $mappedDrives | Where-Object { $_.Name -eq $CheckDriveLetter.TrimEnd(':') }
        if ($checkResult) {
            Write-Host "Drive '$CheckDriveLetter' is successfully mapped to $($checkResult.DisplayRoot)."
            return $true
        } else {
            Write-Host "Drive '$CheckDriveLetter' is not mapped."
            return $false
        }
    }
}

function Create-NetworkDrive {
    [CmdletBinding()]
    param (
        [string]$DriveLetter = "S:",
        [string]$NetworkPath = "\\path\to\network\share", # Ensure this is correct
        [string]$JsonPath
    )

    $credentials = Get-CredentialsFromJson -JsonPath $JsonPath
    if ($credentials) {
        $cmd = "net use $DriveLetter $NetworkPath /user:$($credentials.UserName) $($credentials.GetNetworkCredential().Password) /persistent:yes"
        try {
            Invoke-Expression $cmd
            Start-Sleep -Seconds 2  # Allow some time for the mapping to establish
            if (Get-MappedNetworkDrives -CheckDriveLetter $DriveLetter) {
                Write-Host "Drive '$DriveLetter' mapped successfully to '$NetworkPath'."
            } else {
                Write-Error "Drive '$DriveLetter' mapping failed or is not visible yet."
            }
        } catch {
            Write-Error "Error mapping network drive: $_"
        }
    } else {
        Write-Error "Failed to retrieve credentials from JSON."
    }
}


function Refresh-NetworkDrive {
    param (
        [string]$DriveLetter
    )

    # Check if the drive can be accessed
    if (Test-Path $DriveLetter) {
        Write-Host "Drive $DriveLetter is accessible."
    } else {
        Write-Host "Drive $DriveLetter appears disconnected. Attempting to refresh..."
        # Attempt to remove and then re-add the drive
        net use $DriveLetter /delete
        Start-Sleep -Seconds 2
        $result = net use $DriveLetter
        if ($result -match "successfully") {
            Write-Host "Drive $DriveLetter reconnected successfully."
        } else {
            Write-Error "Failed to reconnect drive $DriveLetter."
        }
    }
}

# Update hosts file
Add-HostsEntry -IPAddress "192.168.100.230" -Hostname "NNOTT-LLW-SL08"

# Create network drive
Create-NetworkDrive -DriveLetter "S:" -NetworkPath "\\NNOTT-LLW-SL08\code" -JsonPath "$PSScriptRoot\secrets.json"

# Optionally refresh network drive state
Refresh-NetworkDrive -DriveLetter "S:"