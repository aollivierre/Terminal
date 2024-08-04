Install-Module -Name EnhancedBoilerPlateAO -Scope AllUsers -Force
Install-Module -Name EnhancedLoggingAO -Scope AllUsers -Force

Write-EnhancedLog "Logging works" -Level "INFO"


function Get-UserProfiles {

    <#
.SYNOPSIS
Retrieves the paths to all user directories under C:\Users and D:\Users.

.DESCRIPTION
This function uses the Get-ChildItem cmdlet to retrieve all directories
under C:\Users and D:\Users. The resulting directories are then returned
as an array.

.EXAMPLE
$userDirectories = Get-UserProfiles

#>

    # Retrieve all directories under C:\Users and D:\Users
    $userDirectories = Get-ChildItem -Path C:\Users, D:\Users -Directory -ErrorAction SilentlyContinue

    # Return the array of user directories
    return $userDirectories
}

function Verify-FileCopy {

    <#
This function copies a file to the specified destination for each user
directory found under C:\Users and D:\Users.

The function takes two parameters:
 - sourceFile: The path to the file to be copied
 - destFile: The path to the destination directory, relative to the user's home directory

The function loops through each user directory, constructs the full path to the destination
directory, and copies the file there. If the destination directory does not exist, the function
creates it.
#>

    param(
        [string]$sourceFilePath,
        [string]$destFilePath,
        [bool]$overwrite = $true
    )
    if (Test-Path -Path $destFilePath) {
        if (-Not $overwrite) {
            Write-Warning "File already exists at destination and overwrite is not allowed: $destFilePath"
            return $false
        }
        Remove-Item -Path $destFilePath -Force # Ensures overwrite
    }

    Copy-Item -Path $sourceFilePath -Destination $destFilePath -Force
    if (-Not (Test-Path -Path $destFilePath)) {
        Write-Error "File copy failed for $sourceFilePath to $destFilePath"
        return $false
    }

    $sourceSize = (Get-Item -Path $sourceFilePath).Length
    $destSize = (Get-Item -Path $destFilePath).Length
    if ($sourceSize -ne $destSize) {
        Write-Error "File sizes do not match after copy."
        return $false
    }

    Write-Host "File successfully copied to $destFilePath"
    return $true
}

function Copy-ProfileToUserDirectory {
    param(
        [string]$sourceFile,
        [string]$destFile,
        [bool]$overwrite = $true
    )
    if (-Not $sourceFile -or -Not $destFile) {
        Write-Error "Source or destination path is empty."
        return
    }

    foreach ($userDir in Get-UserProfiles) {
        $destinationPath = Join-Path -Path $userDir.FullName -ChildPath $destFile
        if (-Not (Test-Path -Path $destinationPath)) {
            New-Item -ItemType Directory -Path $destinationPath -Force
        }
        $fullDestinationPath = Join-Path -Path $destinationPath -ChildPath (Split-Path -Leaf $sourceFile)

        $copySuccess = Verify-FileCopy -sourceFilePath $sourceFile -destFilePath $fullDestinationPath -overwrite $overwrite
        if (-Not $copySuccess) {
            Write-Error "Failed to copy $sourceFile to $fullDestinationPath"
        }
    }
}

function Copy-VSCodeProfiles {

    <#
.SYNOPSIS
Copies the Visual Studio Code profile and settings to the user's Documents\PowerShell\ and
AppData\Roaming\Code\User\ directories respectively.

.DESCRIPTION
This function copies the Visual Studio Code profile and settings to the user's Documents\PowerShell\
and AppData\Roaming\Code\User\ directories respectively. The function takes no parameters.

The source files are located in the following locations relative to the script root:
 - Configs\VSCode\Microsoft.VSCode_profile.ps1
 - Configs\VSCode\settings.json

These files are copied to the following locations relative to the user's home directory:
 - Documents\PowerShell\Microsoft.VSCode_profile.ps1
 - AppData\Roaming\Code\User\settings.json
#>

    $sourceDirectory = Join-Path -Path $PSScriptRoot -ChildPath "Configs\VSCode"
    $vsCodeProfile = Join-Path -Path $sourceDirectory -ChildPath "Microsoft.VSCode_profile.ps1"

    # we will use the Settings Sync through the GitHub Sign in feature
    # $vsCodeSettings = Join-Path -Path $sourceDirectory -ChildPath "settings.json"

    Copy-ProfileToUserDirectory -sourceFile $vsCodeProfile -destFile "Documents\PowerShell\"
    # Copy-ProfileToUserDirectory -sourceFile $vsCodeSettings -destFile "AppData\Roaming\Code\User"
}

function Copy-TerminalSettings {

    <#
.SYNOPSIS
Copies the Windows Terminal settings to the user's AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState directory.

.DESCRIPTION
This function copies the Windows Terminal settings to the user's AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState directory.
The function takes no parameters.

The source file is located in the following location relative to the script root:
 - Configs\Terminal\settings.json

This file is copied to the following location relative to the user's home directory:
 - AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
#>

    $sourceDirectory = Join-Path -Path $PSScriptRoot -ChildPath "Configs\Terminal"
    $terminalSettings = Join-Path -Path $sourceDirectory -ChildPath "settings.json"

    Copy-ProfileToUserDirectory -sourceFile $terminalSettings -destFile "AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
    Copy-ProfileToUserDirectory -sourceFile $terminalSettings -destFile "AppData\Local\Microsoft\Windows Terminal"
}


function Copy-PS7Profiles {
    $sourceDirectory = Join-Path -Path $PSScriptRoot -ChildPath "Configs\PS\7.0"
    $ps7Profile = Join-Path -Path $sourceDirectory -ChildPath "Microsoft.PowerShell_profile.ps1"
    # $vsCodePS7Profile = Join-Path -Path $sourceDirectory -ChildPath "Microsoft.VSCode_profile.ps1"

    Copy-ProfileToUserDirectory -sourceFile $ps7Profile -destFile "Documents\PowerShell"
    # Copy-ProfileToUserDirectory -sourceFile $vsCodePS7Profile -destFile "Documents\PowerShell"
}

function Copy-PS5Profiles {
    $sourceDirectory = Join-Path -Path $PSScriptRoot -ChildPath "Configs\PS\5.1"
    $ps5Profile = Join-Path -Path $sourceDirectory -ChildPath "Microsoft.PowerShell_profile.ps1"
    # $vsCodePS5Profile = Join-Path -Path $sourceDirectory -ChildPath "Microsoft.VSCode_profile.ps1"

    Copy-ProfileToUserDirectory -sourceFile $ps5Profile -destFile "Documents\WindowsPowerShell"
    # Copy-ProfileToUserDirectory -sourceFile $vsCodePS5Profile -destFile "Documents\WindowsPowerShell"
}

# To run these functions:
Copy-PS7Profiles
Copy-PS5Profiles
Copy-VSCodeProfiles
Copy-TerminalSettings