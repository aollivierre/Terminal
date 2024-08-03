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

# Call the function to import the module with retry logic
Import-ModuleWithRetry -ModulePath $LoggingmodulePath
Import-ModuleWithRetry -ModulePath $ModuleUpdatermodulePath




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

Write-EnhancedLog "calling Test-RunningAsSystem" -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
if (-not (Test-RunningAsSystem)) {
    $privateFolderPath = Join-Path -Path $PSScriptRoot -ChildPath "private"
    $PsExec64Path = Join-Path -Path $privateFolderPath -ChildPath "PsExec64.exe"

    Write-EnhancedLog "Current session is not running as SYSTEM. Attempting to invoke as SYSTEM..." -Level "INFO" -ForegroundColor ([ConsoleColor]::Yellow)

    $ScriptToRunAsSystem = $MyInvocation.MyCommand.Path
    Invoke-AsSystem -PsExec64Path $PsExec64Path -ScriptPath $ScriptToRunAsSystem

}
else {
    Write-EnhancedLog "Session is already running as SYSTEM." -Level "INFO" -ForegroundColor ([ConsoleColor]::Green)
}










# function Update-PesterIfOldOrMissing {
#     [CmdletBinding()]
#     param ()

#     Begin {
#         Write-Host "Starting Pester check and update process..." -ForegroundColor Cyan
#     }

#     Process {
#         # Check Pester version status using the provided Check-ModuleVersionStatus function
#         # This function must be defined in the same script or imported from a module
#         Check-ModuleVersionStatus -ModuleNames @('Pester') | ForEach-Object {
#             if ($_.Contains("is outdated")) {
#                 # The message will contain "is outdated" if the installed version is less than the latest version
#                 $moduleName, $currentVersion, $latestVersion = $_ -split '[:.]' | Where-Object { $_ -match 'Pester|\d+\.\d+' }

#                 # Take action to update
#                 Write-Host "Updating Pester from version $currentVersion to $latestVersion." -ForegroundColor Yellow

#                 # Assuming administrative access for module management
#                 $modulePath = (Get-Module -ListAvailable -Name Pester | Sort-Object Version -Descending | Select-Object -First 1).ModuleBase
#                 & takeown.exe /F $modulePath /A /R
#                 & icacls.exe $modulePath /reset
#                 & icacls.exe $modulePath /grant "*S-1-5-32-544:F" /inheritance:d /T
#                 Remove-Item -Path $modulePath -Recurse -Force -Confirm:$false

#                 # Install the latest version of Pester
#                 Install-Module -Name Pester -Force -SkipPublisherCheck
#                 Write-Host "Pester has been updated to the latest version." -ForegroundColor Green
#             } elseif ($_.Contains("is up-to-date") -or $_.Contains("is not installed")) {
#                 # No action needed or Pester not installed, take appropriate response
#                 Write-Host $_ -ForegroundColor Green
#             }
#         }
#     }

#     End {
#         Write-Host "Exiting Pester update function." -ForegroundColor Cyan
#     }
# }

# Update-PesterIfOldOrMissing





# function Update-PesterIfOldOrMissing {
#     [CmdletBinding()]
#     param ()

#     Begin {
#         Write-Host "Starting Pester check and update process..." -ForegroundColor Cyan
#     }

#     Process {
#         $pesterStatus = Check-ModuleVersionStatus -ModuleNames @('Pester')
#         foreach ($status in $pesterStatus) {
#             switch ($status.Status) {
#                 "Outdated" {
#                     Write-Host "Updating Pester from version $($status.InstalledVersion) to $($status.LatestVersion)." -ForegroundColor Yellow

#                     # Assuming administrative access for module management
#                     $modulePath = (Get-Module -ListAvailable -Name 'Pester' | Sort-Object Version -Descending | Select-Object -First 1).ModuleBase
#                     & takeown.exe /F $modulePath /A /R
#                     & icacls.exe $modulePath /reset
#                     & icacls.exe $modulePath /grant "*S-1-5-32-544:F" /inheritance:d /T
#                     Remove-Item -Path $modulePath -Recurse -Force -Confirm:$false

#                     # Install the latest version of Pester
#                     Install-Module -Name Pester -Force -SkipPublisherCheck
#                     Write-Host "Pester has been updated to the latest version." -ForegroundColor Green
#                 }
#                 "Up-to-date" {
#                     Write-Host "Pester version $($status.InstalledVersion) is up-to-date. No update necessary." -ForegroundColor Green
#                 }
#                 "Not Installed" {
#                     Write-Host "Pester is not installed. Installing the latest version..." -ForegroundColor Yellow
#                     Install-Module -Name Pester -Force -SkipPublisherCheck
#                     Write-Host "Pester has been installed." -ForegroundColor Green
#                 }
#                 "Not Found in Gallery" {
#                     Write-Host "Unable to find 'Pester' in the PowerShell Gallery." -ForegroundColor Red
#                 }
#             }
#         }
#     }

#     End {
#         Write-Host "Exiting Pester update function." -ForegroundColor Cyan
#     }
# }

# # Example invocation:
# Update-PesterIfOldOrMissing





function Update-ModuleIfOldOrMissing {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )

    Begin {
        Write-Host "Starting check and update process for module: $ModuleName..." -ForegroundColor Cyan
    }

    Process {
        $moduleStatus = Check-ModuleVersionStatus -ModuleNames @($ModuleName)
        foreach ($status in $moduleStatus) {
            switch ($status.Status) {
                "Outdated" {
                    Write-Host "Updating $ModuleName from version $($status.InstalledVersion) to $($status.LatestVersion)." -ForegroundColor Yellow

                    # Assuming administrative access for module management
                    $modulePath = (Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object -First 1).ModuleBase
                    & takeown.exe /F $modulePath /A /R
                    & icacls.exe $modulePath /reset
                    & icacls.exe $modulePath /grant "*S-1-5-32-544:F" /inheritance:d /T
                    Remove-Item -Path $modulePath -Recurse -Force -Confirm:$false

                    # Install the latest version of the module
                    Install-Module -Name $ModuleName -Force -SkipPublisherCheck
                    Write-Host "$ModuleName has been updated to the latest version." -ForegroundColor Green
                }
                "Up-to-date" {
                    Write-Host "$ModuleName version $($status.InstalledVersion) is up-to-date. No update necessary." -ForegroundColor Green
                }
                "Not Installed" {
                    Write-Host "$ModuleName is not installed. Installing the latest version..." -ForegroundColor Yellow
                    Install-Module -Name $ModuleName -Force -SkipPublisherCheck
                    Write-Host "$ModuleName has been installed." -ForegroundColor Green
                }
                "Not Found in Gallery" {
                    Write-Host "Unable to find '$ModuleName' in the PowerShell Gallery." -ForegroundColor Red
                }
            }
        }
    }

    End {
        Write-Host "Exiting update function for module: $ModuleName." -ForegroundColor Cyan
    }
}

# Example invocation to update or install Pester:
Update-ModuleIfOldOrMissing -ModuleName 'Pester'
