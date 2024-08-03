function Get-CredentialsFromJson {
    [CmdletBinding()]
    param (
        [string]$JsonPath
    )

    if (Test-Path $JsonPath) {
        $jsonContent = Get-Content -Path $JsonPath -Raw | ConvertFrom-Json
        $securePassword = ConvertTo-SecureString -String $jsonContent.password -AsPlainText -Force
        $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $jsonContent.username, $securePassword
        return $credential
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
        $_.DisplayRoot -like '\\*'  # Filter to only network drives
    }
    
    if ($mappedDrives) {
        Write-Host "Current mapped network drives:"
        foreach ($drive in $mappedDrives) {
            Write-Host "Drive Letter: $($drive.Name) - Network Path: $($drive.DisplayRoot)"
        }
    } else {
        Write-Host "No network drives are currently mapped."
    }

    # Validate a specific drive if the CheckDriveLetter parameter is provided
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






# function Create-NetworkDrive {
#     [CmdletBinding()]
#     param (
#         [string]$DriveLetter = "S:",
#         [string]$NetworkPath = "\\path\to\network\share" # Update this with the actual network path
#     )

#     $credentials = Get-CredentialsFromJson -JsonPath "$PSScriptRoot\secrets.json"
#     if ($credentials) {
#         try {
#             # Map the network drive using a drive letter
#             New-PSDrive -Name $DriveLetter.TrimEnd(':') -PSProvider FileSystem -Root $NetworkPath -Credential $credentials -Persist -Scope Global
#             Write-Host "Network drive mapped to '$DriveLetter' at '$NetworkPath'."

#             # Validate the creation of the drive
#             $isValid = Get-MappedNetworkDrives -CheckDriveLetter $DriveLetter
#             if ($isValid) {
#                 Write-Host "Validation confirmed: Drive '$DriveLetter' is correctly mapped."
#             } else {
#                 Write-Error "Validation failed: Drive '$DriveLetter' did not map correctly."
#             }
#         } catch {
#             Write-Error "Failed to map the network drive. Error: $_"
#         }
#     } else {
#         Write-Error "Failed to retrieve credentials."
#     }
# }



# function Create-NetworkDrive {
#     [CmdletBinding()]
#     param (
#         [string]$DriveLetter = "S:",
#         [string]$NetworkPath = "\\path\to\network\share" # Ensure this is correct
#     )

#     $credentials = Get-CredentialsFromJson -JsonPath "$PSScriptRoot\secrets.json"

#     if (-not $credentials) {
#         Write-Error "Failed to retrieve credentials."
#         return
#     }

#     try {
#         # Check if the drive letter is already in use
#         if (Test-Path $DriveLetter) {
#             Write-Warning "Drive '$DriveLetter' is already in use."
#             return
#         }

#         # Attempt to map the network drive
#         $drive = New-PSDrive -Name $DriveLetter.TrimEnd(':') -PSProvider FileSystem -Root $NetworkPath -Credential $credentials -Persist -Scope Global -ErrorAction Stop
#         Write-Host "Network drive mapped to '$DriveLetter' at '$NetworkPath'."

#         # Validate the network path
#         if (Test-Path $DriveLetter) {
#             Write-Host "Validation confirmed: Drive '$DriveLetter' is accessible."
#         } else {
#             Write-Error "Validation failed: Drive '$DriveLetter' is not accessible despite mapping."
#         }
#     } catch {
#         Write-Error "Failed to map the network drive. Error: $_"
#     }
# }


function Create-NetworkDrive {
    [CmdletBinding()]
    param (
        [string]$DriveLetter = "S:",
        [string]$NetworkPath = "\\path\to\network\share", # Ensure this is correct
        [string]$Username,
        [string]$Password
    )

    # Convert to secure string and then to plain text to use with net use
    $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
    $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)

    # Prepare command
    $cmd = "net use $DriveLetter $NetworkPath /user:$Username $plainPassword /persistent:yes"

    try {
        # Execute the command
        Invoke-Expression $cmd

        # Check if the drive is mapped
        if (Test-Path $DriveLetter) {
            Write-Host "Drive '$DriveLetter' mapped successfully to '$NetworkPath'."
        } else {
            Write-Error "Failed to map the drive '$DriveLetter'."
        }
    } catch {
        Write-Error "Error mapping network drive: $_"
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
# Create-NetworkDrive -DriveLetter "S:" -NetworkPath "\\NNOTT-LLW-SL08\code" -DriveName "code"


# This would typically be placed at the part of your script where you need to map the drive.
# Map the network drive using credentials from JSON
# Example usage:
# Create-NetworkDrive -DriveLetter "S:" -NetworkPath "\\NNOTT-LLW-SL08\code"



$credentials = Get-CredentialsFromJson -JsonPath "$PSScriptRoot\secrets.json"
Create-NetworkDrive -DriveLetter "T:" -NetworkPath "\\NNOTT-LLW-SL08\code" -Username $credentials.UserName -Password $credentials.GetNetworkCredential().Password



# Usage
Refresh-NetworkDrive -DriveLetter "T:"
