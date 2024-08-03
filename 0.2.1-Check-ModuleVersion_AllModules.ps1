# # Global setup for paths
# param (
#     [string]$ExportFolderName = "exports-ModuleVersion",
#     [string]$LogFileName = "exports-ModuleVersion"
# )

# # Global setup for paths
# $timestamp = Get-Date -Format "yyyyMMddHHmmss"
# $exportFolder = Join-Path -Path $PSScriptRoot -ChildPath $ExportFolderName


# $BaseOutputPath = Join-Path -Path $exportFolder -ChildPath "${ExportFolderName}_$timestamp"


#  # Ensure the export directory exists
#  if (-not (Test-Path -Path $BaseOutputPath)) {
#     New-Item -ItemType Directory -Path $BaseOutputPath | Out-Null
# }










# function Initialize-ExportEnvironment {
    param (
        [string]$ExportFolderName = "exports-ModuleVersion",
        [string]$LogFileName = "exports-ModuleVersion"
    )

    # Log input parameters
    Write-Host "ExportFolderName: $ExportFolderName"
    Write-Host "LogFileName: $LogFileName"

    # Calculate the timestamp
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    Write-Host "Timestamp: $timestamp"

    # Determine base paths
    $exportFolder = Join-Path -Path $PSScriptRoot -ChildPath $ExportFolderName
    Write-Host "PSScript Root: $PSScriptRoot"
    Write-Host "Export Folder Path: $exportFolder"

    $BaseOutputPath = Join-Path -Path $exportFolder -ChildPath "${ExportFolderName}_$timestamp"
    Write-Host "Base Output Path: $BaseOutputPath"

    # Ensure the export directory exists
    if (-not (Test-Path -Path $BaseOutputPath)) {
        New-Item -ItemType Directory -Path $BaseOutputPath | Out-Null
        Write-Host "Created directory: $BaseOutputPath"
    } else {
        Write-Host "Directory already exists: $BaseOutputPath"
    }
# }

# To run the function, you can simply call it like this:
# Initialize-ExportEnvironment



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
# $WinGetWrappermodulePath = Join-Path -Path $PSScriptRoot -ChildPath "Private\WingetWrapper\1.0.0\WingetWrapper.psm1"

# Call the function to import the module with retry logic
Import-ModuleWithRetry -ModulePath $LoggingmodulePath
Import-ModuleWithRetry -ModulePath $ModuleUpdatermodulePath
# Import-ModuleWithRetry -ModulePath $WinGetWrappermodulePath




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


# D:\code\CB\Terminal\Private\WingetWrapper\1.0.0\Public\WinGet-WrapperDetection.ps1

# winget install JanDeDobbeleer.OhMyPosh -s winget







CheckAndElevate






function Install-MissingModules {
    <#
.SYNOPSIS
Installs missing PowerShell modules from a given list of module names.

.DESCRIPTION
The Install-MissingModules function checks a list of PowerShell module names and installs any that are not already installed on the system. This function requires administrative privileges to install modules for all users.

.PARAMETER RequiredModules
An array of module names that you want to ensure are installed on the system.

.EXAMPLE
PS> $modules = @('ImportExcel', 'powershell-yaml')
PS> Install-MissingModules -RequiredModules $modules

This example checks for the presence of the 'ImportExcel' and 'powershell-yaml' modules and installs them if they are not already installed.
#>


    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$RequiredModules
    )

    Begin {
        Write-Host "Starting to check and install required modules..."
    }

    Process {
        foreach ($module in $RequiredModules) {
            if (-not (Get-Module -ListAvailable -Name $module)) {
                Write-Host "Module '$module' is not installed. Attempting to install..."
                try {
                    Install-Module -Name $module -Force -Scope AllUsers
                    Write-Host "Module '$module' installed successfully."
                }
                catch {
                    Write-Error "Failed to install module '$module'. Error: $_"
                }
            }
            else {
                Write-Host "Module '$module' is already installed."
            }
        }
    }

    End {
        Write-Host "Completed checking and installing modules."
    }
}

# Example usage
# $modules = @('ImportExcel', 'powershell-yaml' , 'MarkdownModule')
$modules = @('ImportExcel', 'powershell-yaml' , 'PSWriteHTML')
Install-MissingModules -RequiredModules $modules -Verbose





function Export-Data {
    <#
.SYNOPSIS
Exports data to various formats including CSV, JSON, XML, HTML, PlainText, Excel, PDF, Markdown, and YAML.

.DESCRIPTION
The Export-Data function exports provided data to multiple file formats based on switches provided. It supports CSV, JSON, XML, GridView (for display only), HTML, PlainText, Excel, PDF, Markdown, and YAML formats. This function is designed to work with any PSObject.

.PARAMETER Data
The data to be exported. This parameter accepts input of type PSObject.

.PARAMETER BaseOutputPath
The base path for output files without file extension. This path is used to generate filenames for each export format.

.PARAMETER IncludeCSV
Switch to include CSV format in the export.

.PARAMETER IncludeJSON
Switch to include JSON format in the export.

.PARAMETER IncludeXML
Switch to include XML format in the export.

.PARAMETER IncludeGridView
Switch to display the data in a GridView.

.PARAMETER IncludeHTML
Switch to include HTML format in the export.

.PARAMETER IncludePlainText
Switch to include PlainText format in the export.

.PARAMETER IncludePDF
Switch to include PDF format in the export. Requires intermediate HTML to PDF conversion.

.PARAMETER IncludeExcel
Switch to include Excel format in the export.

.PARAMETER IncludeMarkdown
Switch to include Markdown format in the export. Custom or use a module if available.

.PARAMETER IncludeYAML
Switch to include YAML format in the export. Requires 'powershell-yaml' module.

.EXAMPLE
PS> $data = Get-Process | Select-Object -First 10
PS> Export-Data -Data $data -BaseOutputPath "C:\exports\mydata" -IncludeCSV -IncludeJSON

This example exports the first 10 processes to CSV and JSON formats.
#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [psobject]$Data,

        [Parameter(Mandatory = $true)]
        [string]$BaseOutputPath,

        [switch]$IncludeCSV,
        [switch]$IncludeJSON,
        [switch]$IncludeXML,
        [switch]$IncludeGridView,
        [switch]$IncludeHTML,
        [switch]$IncludePlainText,
        [switch]$IncludePDF, # Requires intermediate HTML to PDF conversion
        [switch]$IncludeExcel,
        [switch]$IncludeMarkdown, # Custom or use a module if available
        [switch]$IncludeYAML  # Requires 'powershell-yaml' module
    )

    Begin {
        # Setup the base path without extension
        # $basePathWithoutExtension = [System.IO.Path]::ChangeExtension($BaseOutputPath, "")
        # Prepare the base path without extension correctly, ensuring no trailing period
        Write-Host "BaseOutputPath before change: '$BaseOutputPath'"
        $basePathWithoutExtension = [System.IO.Path]::ChangeExtension($BaseOutputPath, $null)

        # Remove extension manually if it exists
        $basePathWithoutExtension = if ($BaseOutputPath -match '\.') {
            $BaseOutputPath.Substring(0, $BaseOutputPath.LastIndexOf('.'))
        }
        else {
            $BaseOutputPath
        }

        # Ensure no trailing periods
        $basePathWithoutExtension = Join-Path -Path $basePathWithoutExtension.TrimEnd('.') -ChildPath "${ExportFolderName}_$Timestamp"
        # $basePathWithoutExtension = $basePathWithoutExtension.TrimEnd('.')
        Write-Host "BaseOutputPath after change without extension: '$basePathWithoutExtension'"


    }

    Process {
        try {
            if ($IncludeCSV) {
                $csvPath = "$basePathWithoutExtension.csv"
                $Data | Export-Csv -Path $csvPath -NoTypeInformation
            }

            if ($IncludeJSON) {
                $jsonPath = "$basePathWithoutExtension.json"
                $Data | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath
            }

            if ($IncludeXML) {
                $xmlPath = "$basePathWithoutExtension.xml"
                $Data | Export-Clixml -Path $xmlPath
            }

            if ($IncludeGridView) {
                $Data | Out-GridView -Title "Data Preview"
            }

            if ($IncludeHTML) {
                # Assumes $Data is the dataset you want to export to HTML
                # and $basePathWithoutExtension is prepared earlier in your script
                
                $htmlPath = "$basePathWithoutExtension.html"
                
                # Convert $Data to HTML using PSWriteHTML
                New-HTML -Title "Data Export Report" -FilePath $htmlPath -ShowHTML {
                    New-HTMLSection -HeaderText "Data Export Details" -Content {
                        New-HTMLTable -DataTable $Data -ScrollX -HideFooter
                    }
                }
            
                Write-Host "HTML report generated: '$htmlPath'"
            }
            

            if ($IncludePlainText) {
                $txtPath = "$basePathWithoutExtension.txt"
                $Data | Out-String | Set-Content -Path $txtPath
            }

            if ($IncludeExcel) {
                $excelPath = "$basePathWithoutExtension.xlsx"
                $Data | Export-Excel -Path $excelPath
            }

            # Assuming $Data holds the objects you want to serialize to YAML
            if ($IncludeYAML) {
                $yamlPath = "$basePathWithoutExtension.yaml"
    
                # Check if the powershell-yaml module is loaded
                if (Get-Module -ListAvailable -Name powershell-yaml) {
                    Import-Module powershell-yaml

                    # Process $Data to handle potentially problematic properties
                    $processedData = $Data | ForEach-Object {
                        $originalObject = $_
                        $properties = $_ | Get-Member -MemberType Properties
                        $clonedObject = New-Object -TypeName PSObject

                        foreach ($prop in $properties) {
                            try {
                                $clonedObject | Add-Member -MemberType NoteProperty -Name $prop.Name -Value $originalObject.$($prop.Name) -ErrorAction Stop
                            }
                            catch {
                                # Optionally handle or log the error. Skipping problematic property.
                                $clonedObject | Add-Member -MemberType NoteProperty -Name $prop.Name -Value "Error serializing property" -ErrorAction SilentlyContinue
                            }
                        }

                        return $clonedObject
                    }

                    # Convert the processed data to YAML and save it with UTF-16 LE encoding
                    $processedData | ConvertTo-Yaml | Set-Content -Path $yamlPath -Encoding Unicode
                    Write-Host "YAML export completed successfully: $yamlPath"
                }
                else {
                    Write-Warning "The 'powershell-yaml' module is not installed. YAML export skipped."
                }
            }




            

            # Markdown and PDF export logic goes here
            # Reminder: Implement or handle with appropriate functions or modules

            # Markdown and PDF are more complex due to their need for specific formatting or conversion tools
            if ($IncludeMarkdown) {
                # You'll need to implement or find a ConvertTo-Markdown function or use a suitable module
                $markdownPath = "$basePathWithoutExtension.md"
                $Data | ConvertTo-Markdown | Set-Content -Path $markdownPath
            }

            if ($IncludePDF) {
                # Convert HTML to PDF using external tool
                # This is a placeholder for the process. You will need to generate HTML first and then convert it.
                $pdfPath = "$basePathWithoutExtension.pdf"
                # Assuming you have a Convert-HtmlToPdf function or a similar mechanism
                $htmlPath = "$basePathWithoutExtension.html"
                $Data | ConvertTo-Html | Convert-HtmlToPdf -OutputPath $pdfPath
            }

        }
        catch {
            Write-Error "An error occurred during export: $_"
        }
    }

    End {
        Write-Host "Export-Data function execution completed."
    }
}









# function Check-AllModuleVersions {
#     # [CmdletBinding()]
#     Import-Module -Name PowerShellGet -ErrorAction SilentlyContinue

#     $allInstalledModules = Get-Module -ListAvailable | Select-Object -Unique

#     foreach ($installedModule in $allInstalledModules) {
#         try {
#             $latestModule = Find-Module -Name $installedModule.Name -ErrorAction SilentlyContinue

#             if ($latestModule) {
#                 if ($installedModule.Version -lt $latestModule.Version) {
#                     Write-Host "Module '$($installedModule.Name)' is outdated. Installed version: $($installedModule.Version). Latest version: $($latestModule.Version)." -ForegroundColor Red
#                 } else {
#                     Write-Host "Module '$($installedModule.Name)' is up-to-date with the latest version: $($installedModule.Version)." -ForegroundColor Green
#                 }
#             } else {
#                 Write-Host "No version of module '$($installedModule.Name)' found in the PowerShell Gallery." -ForegroundColor Yellow
#             }
#         } catch {
#             Write-Error "An error occurred checking module '$($installedModule.Name)': $_"
#         }
#     }
# }



# Check-AllModuleVersions













# function Check-AllModuleVersions {
#     # [CmdletBinding()]
#     Import-Module -Name PowerShellGet -ErrorAction SilentlyContinue

#     # Initialize a list to hold output data for exporting
#     $moduleVersionInfo = New-Object System.Collections.Generic.List[Object]

#     $allInstalledModules = Get-Module -ListAvailable | Select-Object -Unique

#     foreach ($installedModule in $allInstalledModules) {
#         try {
#             $latestModule = Find-Module -Name $installedModule.Name -ErrorAction SilentlyContinue
#             $status = $null

#             if ($latestModule) {
#                 if ($installedModule.Version -lt $latestModule.Version) {
#                     $status = "Module '$($installedModule.Name)' is outdated. Installed version: $($installedModule.Version). Latest version: $($latestModule.Version)."
#                     Write-Host $status -ForegroundColor Red
#                 } else {
#                     $status = "Module '$($installedModule.Name)' is up-to-date with the latest version: $($installedModule.Version)."
#                     Write-Host $status -ForegroundColor Green
#                 }
#             } else {
#                 $status = "No version of module '$($installedModule.Name)' found in the PowerShell Gallery."
#                 Write-Host $status -ForegroundColor Yellow
#             }

#             if ($status) {
#                 $moduleVersionInfo.Add([PSCustomObject]@{
#                     ModuleName       = $installedModule.Name
#                     InstalledVersion = $installedModule.Version
#                     LatestVersion    = $latestModule?.Version
#                     Status           = $status
#                 })
#             }

#         } catch {
#             Write-Error "An error occurred checking module '$($installedModule.Name)': $_"
#         }
#     }

#     # Assuming $exportParams is defined globally or outside this function
#     # $exportParams['Data'] = $moduleVersionInfo
#     # Export-Data @exportParams




#     $exportParams = @{
#         Data             = $moduleVersionInfo
#         BaseOutputPath   = $BaseOutputPath
#         IncludeCSV       = $true
#         IncludeJSON      = $true
#         IncludeXML       = $true
#         IncludeHTML      = $true
#         IncludePlainText = $true
#         IncludeExcel     = $true
#         # IncludePDF       = $true
#         # IncludeMarkdown = $true
#         IncludeYAML      = $true
#         IncludeGridView  = $true  # Note: GridView displays data but doesn't export/save it
#     }
    
#     # Call the Export-Data function with splatted parameters
#     Export-Data @exportParams
# }




# Check-AllModuleVersions




# function Check-AllModuleVersions {
#     Import-Module -Name PowerShellGet -ErrorAction SilentlyContinue

#     # Initialize a list to hold output data for exporting
#     $moduleVersionInfo = New-Object System.Collections.Generic.List[Object]

#     $allInstalledModules = Get-Module -ListAvailable | Select-Object -Unique

#     foreach ($installedModule in $allInstalledModules) {
#         try {
#             $latestModule = Find-Module -Name $installedModule.Name -ErrorAction SilentlyContinue
#             $status = $null
#             $updated = $null

#             if ($latestModule) {
#                 if ($installedModule.Version -lt $latestModule.Version) {
#                     $status = "outdated"
#                     $updated = "False"
#                     Write-Host "Module '$($installedModule.Name)' is outdated. Installed version: $($installedModule.Version). Latest version: $($latestModule.Version)." -ForegroundColor Red
#                 } else {
#                     $status = "up-to-date"
#                     $updated = "True"
#                     Write-Host "Module '$($installedModule.Name)' is up-to-date with the latest version: $($installedModule.Version)." -ForegroundColor Green
#                 }
#             } else {
#                 $status = "not found in PS Gallery"
#                 $updated = "Not found and not installed"
#                 Write-Host "No version of module '$($installedModule.Name)' found in the PowerShell Gallery." -ForegroundColor Yellow
#             }

#             $moduleVersionInfo.Add([PSCustomObject]@{
#                 ModuleName       = $installedModule.Name
#                 InstalledVersion = $installedModule.Version
#                 LatestVersion    = $latestModule?.Version
#                 ModuleBase       = $installedModule.ModuleBase
#                 ModulePath       = $installedModule.Path
#                 Status           = $status
#                 Updated          = $updated
#             })

#         } catch {
#             Write-Error "An error occurred checking module '$($installedModule.Name)': $_"
#         }
#     }

#     $exportParams = @{
#         Data             = $moduleVersionInfo
#         BaseOutputPath   = $BaseOutputPath
#         IncludeCSV       = $true
#         IncludeJSON      = $true
#         IncludeXML       = $true
#         IncludeHTML      = $true
#         IncludePlainText = $true
#         IncludeExcel     = $true
#         IncludeYAML      = $true
#         IncludeGridView  = $true  # Note: GridView displays data but doesn't export/save it
#     }
    
#     # Call the Export-Data function with splatted parameters
#     Export-Data @exportParams
# }


# Check-AllModuleVersions













function Check-AllModuleVersions {
    Import-Module -Name PowerShellGet -ErrorAction SilentlyContinue

    # Initialize a list to hold output data for exporting
    $moduleVersionInfo = New-Object System.Collections.Generic.List[Object]

    $allInstalledModules = Get-Module -ListAvailable | Select-Object -Unique

    foreach ($installedModule in $allInstalledModules) {
        try {
            $latestModule = Find-Module -Name $installedModule.Name -ErrorAction SilentlyContinue
            $status = $null
            $updated = $null
            $latestVersion = $null

            if ($latestModule) {
                $latestVersion = $latestModule.Version
                if ($installedModule.Version -lt $latestModule.Version) {
                    $status = "outdated"
                    $updated = "False"
                    Write-Host "Module '$($installedModule.Name)' is outdated. Installed version: $($installedModule.Version). Latest version: $($latestModule.Version)." -ForegroundColor Red
                } else {
                    $status = "up-to-date"
                    $updated = "True"
                    Write-Host "Module '$($installedModule.Name)' is up-to-date with the latest version: $($installedModule.Version)." -ForegroundColor Green
                }
            } else {
                $status = "not found in PS Gallery"
                $updated = "Not found and not installed"
                Write-Host "No version of module '$($installedModule.Name)' found in the PowerShell Gallery." -ForegroundColor Yellow
            }

            $moduleVersionInfo.Add([PSCustomObject]@{
                ModuleName       = $installedModule.Name
                InstalledVersion = $installedModule.Version.ToString()
                LatestVersion    = $latestVersion
                ModuleBase       = $installedModule.ModuleBase
                ModulePath       = $installedModule.Path
                Status           = $status
                Updated          = $updated
            })

        } catch {
            Write-Error "An error occurred checking module '$($installedModule.Name)': $_"
            $moduleVersionInfo.Add([PSCustomObject]@{
                ModuleName       = $installedModule.Name
                InstalledVersion = $installedModule.Version.ToString()
                LatestVersion    = "Error checking version"
                ModuleBase       = $installedModule.ModuleBase
                ModulePath       = $installedModule.Path
                Status           = "Error"
                Updated          = "Error"
            })
        }
    }

    $exportParams = @{
        Data             = $moduleVersionInfo
        BaseOutputPath   = $BaseOutputPath
        IncludeCSV       = $true
        IncludeJSON      = $true
        IncludeXML       = $true
        IncludeHTML      = $true
        IncludePlainText = $true
        IncludeExcel     = $true
        IncludeYAML      = $true
        IncludeGridView  = $true  # Note: GridView displays data but doesn't export/save it
    }
    
    # Call the Export-Data function with splatted parameters
    Export-Data @exportParams
}



Check-AllModuleVersions