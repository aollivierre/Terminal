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
function Get-UserProfiles {
    # Retrieve all directories under C:\Users and D:\Users
    $userDirectories = Get-ChildItem -Path C:\Users, D:\Users -Directory -ErrorAction SilentlyContinue

    # Return the array of user directories
    return $userDirectories
}

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
function Copy-ProfileToUserDirectory {
    param(
        [string]$sourceFile,
        [string]$destFile
    )
    foreach ($userDir in Get-UserProfiles) {
        $destinationPath = Join-Path -Path $userDir.FullName -ChildPath $destFile
        if (-Not (Test-Path -Path $destinationPath)) {
            New-Item -ItemType Directory -Path $destinationPath -Force
        }
        $fullDestinationPath = Join-Path -Path $destinationPath -ChildPath (Split-Path -Leaf $sourceFile)
        Copy-Item -Path $sourceFile -Destination $fullDestinationPath -Force
        Write-Host "Config copied to $fullDestinationPath"
    }
}

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
function Copy-VSCodeProfiles {
    $sourceDirectory = Join-Path -Path $PSScriptRoot -ChildPath "Configs\VSCode"
    $vsCodeProfile = Join-Path -Path $sourceDirectory -ChildPath "Microsoft.VSCode_profile.ps1"
    $vsCodeSettings = Join-Path -Path $sourceDirectory -ChildPath "settings.json"

    Copy-ProfileToUserDirectory -sourceFile $vsCodeProfile -destFile "Documents\PowerShell\"
    Copy-ProfileToUserDirectory -sourceFile $vsCodeSettings -destFile "AppData\Roaming\Code\User"
}

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
function Copy-TerminalSettings {
    $sourceDirectory = Join-Path -Path $PSScriptRoot -ChildPath "Configs\Terminal"
    $terminalSettings = Join-Path -Path $sourceDirectory -ChildPath "settings.json"

    Copy-ProfileToUserDirectory -sourceFile $terminalSettings -destFile "AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
}



function Copy-PS7Profiles {
    $sourceDirectory = Join-Path -Path $PSScriptRoot -ChildPath "Configs\PS\7.0"
    $ps7Profile = Join-Path -Path $sourceDirectory -ChildPath "Microsoft.PowerShell_profile.ps1"
    $vsCodePS7Profile = Join-Path -Path $sourceDirectory -ChildPath "Microsoft.VSCode_profile.ps1"

    Copy-ProfileToUserDirectory -sourceFile $ps7Profile -destFile "Documents\PowerShell"
    Copy-ProfileToUserDirectory -sourceFile $vsCodePS7Profile -destFile "Documents\PowerShell"
}

function Copy-PS5Profiles {
    $sourceDirectory = Join-Path -Path $PSScriptRoot -ChildPath "Configs\PS\5.1"
    $ps5Profile = Join-Path -Path $sourceDirectory -ChildPath "Microsoft.PowerShell_profile.ps1"
    $vsCodePS5Profile = Join-Path -Path $sourceDirectory -ChildPath "Microsoft.VSCode_profile.ps1"

    Copy-ProfileToUserDirectory -sourceFile $ps5Profile -destFile "Documents\WindowsPowerShell"
    Copy-ProfileToUserDirectory -sourceFile $vsCodePS5Profile -destFile "Documents\WindowsPowerShell"
}




# To run these functions:
Copy-PS7Profiles
Copy-PS5Profiles
Copy-VSCodeProfiles
Copy-TerminalSettings