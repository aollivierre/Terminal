$configPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
$env:MYMODULE_CONFIG_PATH = $configPath


<#
.SYNOPSIS
Dot-sources all PowerShell scripts in the 'private' folder relative to the script root.

.DESCRIPTION
This function finds all PowerShell (.ps1) scripts in a 'private' folder located in the script root directory and dot-sources them. It logs the process, including any errors encountered, with optional color coding.

.EXAMPLE
Dot-SourcePrivateScripts

Dot-sources all scripts in the 'private' folder and logs the process.

.NOTES
Ensure the Write-EnhancedLog function is defined before using this function for logging purposes.
#>

function Get-PrivateScriptPathsAndVariables {
    param (
        [string]$BaseDirectory
    )

    try {
        $privateFolderPath = Join-Path -Path $BaseDirectory -ChildPath "private"
    
        if (-not (Test-Path -Path $privateFolderPath)) {
            throw "Private folder path does not exist: $privateFolderPath"
        }

        # Construct and return a PSCustomObject
        return [PSCustomObject]@{
            BaseDirectory     = $BaseDirectory
            PrivateFolderPath = $privateFolderPath
        }
    }
    catch {
        Write-Host "Error in finding private script files: $_" -ForegroundColor Red
        # Optionally, you could return a PSCustomObject indicating an error state
        # return [PSCustomObject]@{ Error = $_.Exception.Message }
    }
}



# Retrieve script paths and related variables
$DotSourcinginitializationInfo = Get-PrivateScriptPathsAndVariables -BaseDirectory $PSScriptRoot

# $DotSourcinginitializationInfo
$DotSourcinginitializationInfo | Format-List


function Import-ModuleWithRetry {

    <#
.SYNOPSIS
Imports a PowerShell module with retries on failure.

.DESCRIPTION
This function attempts to import a specified PowerShell module, retrying the import process up to a specified number of times upon failure. It waits for a specified delay between retries. The function uses advanced logging to provide detailed feedback about the import process.

.PARAMETER ModulePath
The path to the PowerShell module file (.psm1) that should be imported.

.PARAMETER MaxRetries
The maximum number of retries to attempt if importing the module fails. Default is 30.

.PARAMETER WaitTimeSeconds
The number of seconds to wait between retry attempts. Default is 2 seconds.

.EXAMPLE
$modulePath = "C:\Modules\MyPowerShellModule.psm1"
Import-ModuleWithRetry -ModulePath $modulePath

Tries to import the module located at "C:\Modules\MyPowerShellModule.psm1", with up to 30 retries, waiting 2 seconds between each retry.

.NOTES
This function requires the `Write-EnhancedLog` function to be defined in the script for logging purposes.

.LINK
Write-EnhancedLog

#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ModulePath,

        [int]$MaxRetries = 30,

        [int]$WaitTimeSeconds = 2
    )

    Begin {
        $retryCount = 0
        $isModuleLoaded = $false
        # Write-EnhancedLog "Starting to import module from path: $ModulePath" -Level "INFO"
        Write-host "Starting to import module from path: $ModulePath"
    }

    Process {
        while (-not $isModuleLoaded -and $retryCount -lt $MaxRetries) {
            try {
                Import-Module $ModulePath -ErrorAction Stop
                $isModuleLoaded = $true
                Write-EnhancedLog "Module $ModulePath imported successfully." -Level "INFO"
            }
            catch {
                # Write-EnhancedLog "Attempt $retryCount to load module failed. Waiting $WaitTimeSeconds seconds before retrying." -Level "WARNING"
                Write-host "Attempt $retryCount to load module failed. Waiting $WaitTimeSeconds seconds before retrying."
                Start-Sleep -Seconds $WaitTimeSeconds
            }
            finally {
                $retryCount++
            }

            if ($retryCount -eq $MaxRetries -and -not $isModuleLoaded) {
                # Write-EnhancedLog "Failed to import module after $MaxRetries retries." -Level "ERROR"
                Write-host "Failed to import module after $MaxRetries retries."
                break
            }
        }
    }

    End {
        if ($isModuleLoaded) {
            Write-EnhancedLog "Module $ModulePath loaded successfully." -Level "INFO"
        }
        else {
            # Write-EnhancedLog "Failed to load module $ModulePath within the maximum retry limit." -Level "CRITICAL"
            Write-host "Failed to load module $ModulePath within the maximum retry limit."
        }
    }
}

# Example of how to use the function
# $PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$LoggingmodulePath = Join-Path -Path $PSScriptRoot -ChildPath "Private\EnhancedLoggingAO\2.0.0\EnhancedLoggingAO.psm1"
$ModuleUpdatermodulePath = Join-Path -Path $PSScriptRoot -ChildPath "Private\EnhancedModuleUpdaterAO\1.0.0\EnhancedModuleUpdaterAO.psm1"
$WinGetWrappermodulePath = Join-Path -Path $PSScriptRoot -ChildPath "Private\WingetWrapper\1.0.0\WingetWrapper.psm1"

# Call the function to import the module with retry logic
Import-ModuleWithRetry -ModulePath $LoggingmodulePath
Import-ModuleWithRetry -ModulePath $ModuleUpdatermodulePath
Import-ModuleWithRetry -ModulePath $WinGetWrappermodulePath




# ################################################################################################################################
# ################################################ END MODULE LOADING ############################################################
# ################################################################################################################################




function Ensure-LoggingFunctionExists {
    if (Get-Command Write-EnhancedLog -ErrorAction SilentlyContinue) {
        Write-EnhancedLog "Logging works" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
    }
    else {
        throw "Write-EnhancedLog function not found. Terminating script."
    }
}

# Usage
try {
    Ensure-LoggingFunctionExists
    # Continue with the rest of the script here
    # exit
}
catch {
    Write-Host "Critical error: $_" -ForegroundColor Red
    exit
}
    








function Test-RunningAsSystem {
    $systemSid = New-Object System.Security.Principal.SecurityIdentifier "S-1-5-18"
    $currentSid = [System.Security.Principal.WindowsIdentity]::GetCurrent().User

    return $currentSid -eq $systemSid
}


function CheckAndElevate {

    <#
.SYNOPSIS
Elevates the script to run with administrative privileges if not already running as an administrator.

.DESCRIPTION
The CheckAndElevate function checks if the current PowerShell session is running with administrative privileges. If it is not, the function attempts to restart the script with elevated privileges using the 'RunAs' verb. This is useful for scripts that require administrative privileges to perform their tasks.

.EXAMPLE
CheckAndElevate

Checks the current session for administrative privileges and elevates if necessary.

.NOTES
This function will cause the script to exit and restart if it is not already running with administrative privileges. Ensure that any state or data required after elevation is managed appropriately.
#>
    [CmdletBinding()]
    param (
        # Advanced parameters could be added here if needed. For this function, parameters aren't strictly necessary,
        # but you could, for example, add parameters to control logging behavior or to specify a different method of elevation.
        # [switch]$Elevated
    )

    begin {
        try {
            $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
            $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

            Write-EnhancedLog "Checking for administrative privileges..." -Level "INFO" -ForegroundColor ([ConsoleColor]::Blue)
        }
        catch {
            Write-EnhancedLog "Error determining administrative status: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
            throw $_
        }
    }

    process {
        if (-not $isAdmin) {
            try {
                Write-EnhancedLog "The script is not running with administrative privileges. Attempting to elevate..." -Level "WARNING" -ForegroundColor ([ConsoleColor]::Yellow)
            
                $arguments = "-NoProfile -ExecutionPolicy Bypass -NoExit -File `"$PSCommandPath`" $args"
                Start-Process PowerShell -Verb RunAs -ArgumentList $arguments
                # Start-Process Pwsh -Verb RunAs -ArgumentList $arguments

                # Invoke-AsSystem -PsExec64Path $PsExec64Path
            
                Write-EnhancedLog "Script re-launched with administrative privileges. Exiting current session." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
                exit
            }
            catch {
                Write-EnhancedLog "Failed to elevate privileges: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
                throw $_
            }
        }
        else {
            Write-EnhancedLog "Script is already running with administrative privileges." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
        }
    }

    end {
        # This block is typically used for cleanup. In this case, there's nothing to clean up,
        # but it's useful to know about this structure for more complex functions.
    }
}





function Invoke-AsSystem {
    <#
.SYNOPSIS
Executes a PowerShell script under the SYSTEM context, similar to Intune's execution context.

.DESCRIPTION
The Invoke-AsSystem function executes a PowerShell script using PsExec64.exe to run under the SYSTEM context. This method is useful for scenarios requiring elevated privileges beyond the current user's capabilities.

.PARAMETER PsExec64Path
Specifies the full path to PsExec64.exe. If not provided, it assumes PsExec64.exe is in the same directory as the script.

.EXAMPLE
Invoke-AsSystem -PsExec64Path "C:\Tools\PsExec64.exe"

Executes PowerShell as SYSTEM using PsExec64.exe located at "C:\Tools\PsExec64.exe".

.NOTES
Ensure PsExec64.exe is available and the script has the necessary permissions to execute it.

.LINK
https://docs.microsoft.com/en-us/sysinternals/downloads/psexec
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PsExec64Path,
        [string]$ScriptPathAsSYSTEM  # Path to the PowerShell script you want to run as SYSTEM
    )

    begin {
        CheckAndElevate
        # Define the arguments for PsExec64.exe to run PowerShell as SYSTEM with the script
        $argList = "-accepteula -i -s -d powershell.exe -NoExit -ExecutionPolicy Bypass -File `"$ScriptPathAsSYSTEM`""
        Write-EnhancedLog "Preparing to execute PowerShell as SYSTEM using PsExec64 with the script: $ScriptPathAsSYSTEM" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
    }

    process {
        try {
            # Ensure PsExec64Path exists
            if (-not (Test-Path -Path $PsExec64Path)) {
                $errorMessage = "PsExec64.exe not found at path: $PsExec64Path"
                Write-EnhancedLog $errorMessage -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
                throw $errorMessage
            }

            # Run PsExec64.exe with the defined arguments to execute the script as SYSTEM
            $executingMessage = "Executing PsExec64.exe to start PowerShell as SYSTEM running script: $ScriptPathAsSYSTEM"
            Write-EnhancedLog $executingMessage -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
            Start-Process -FilePath "$PsExec64Path" -ArgumentList $argList -Wait -NoNewWindow
        
            Write-EnhancedLog "SYSTEM session started. Closing elevated session..." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
            exit

        }
        catch {
            Write-EnhancedLog "An error occurred: $_" -Level "ERROR" -ForegroundColor ([ConsoleColor]::Red)
        }
    }
}




# Assuming Invoke-AsSystem and Write-EnhancedLog are already defined
# Update the path to your actual location of PsExec64.exe

# Write-EnhancedLog "calling Test-RunningAsSystem" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
# if (-not (Test-RunningAsSystem)) {
#     $privateFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "private"
#     $PsExec64Path = Join-Path -Path $privateFolderPath -ChildPath "PsExec64.exe"

#     Write-EnhancedLog "Current session is not running as SYSTEM. Attempting to invoke as SYSTEM..." -Level "INFO" -ForegroundColor ([ConsoleColor]::Yellow)

#     $ScriptToRunAsSystem = $MyInvocation.MyCommand.Path
#     Invoke-AsSystem -PsExec64Path $PsExec64Path -ScriptPath $ScriptToRunAsSystem

# }
# else {
#     Write-EnhancedLog "Session is already running as SYSTEM." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
# }



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



function Verify-FileCopy {
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

    # we will use the Settings Sync through the GitHub Sign in feature
    # $vsCodeSettings = Join-Path -Path $sourceDirectory -ChildPath "settings.json"

    Copy-ProfileToUserDirectory -sourceFile $vsCodeProfile -destFile "Documents\PowerShell\"
    # Copy-ProfileToUserDirectory -sourceFile $vsCodeSettings -destFile "AppData\Roaming\Code\User"
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