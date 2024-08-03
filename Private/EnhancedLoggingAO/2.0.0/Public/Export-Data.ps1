# param (
#     [string]$ExportFolderName = "IPV4Scan-v1"
#     # [string]$LogFileName = "exports-EnabledMemberDuplicatesExcludingGuests-v7Log"
# )

# # Global setup for paths


# $timestamp = Get-Date -Format "yyyyMMddHHmmss"
# $exportFolder = Join-Path -Path $PSScriptRoot -ChildPath $ExportFolderName_$timestamp
# # $logPath = Join-Path -Path $exportFolder -ChildPath "${LogFileName}_$timestamp.txt"

# # Ensure the exports folder and log file are ready
# if (-not (Test-Path -Path $exportFolder)) {
#     New-Item -ItemType Directory -Path $exportFolder | Out-Null
# }

# Define the Write-Log function
# function Write-Log {
#     param (
#         [Parameter(Mandatory = $true)]
#         [string]$Message,
#         [ConsoleColor]$Color = 'White'
#     )
#     Write-Host $Message -ForegroundColor $Color
#     Add-Content -Path $logPath -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
# }


# $configPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
# $env:MYMODULE_CONFIG_PATH = $configPath


# <#
# .SYNOPSIS
# Dot-sources all PowerShell scripts in the 'private' folder relative to the script root.

# .DESCRIPTION
# This function finds all PowerShell (.ps1) scripts in a 'private' folder located in the script root directory and dot-sources them. It logs the process, including any errors encountered, with optional color coding.

# .EXAMPLE
# Dot-SourcePrivateScripts

# Dot-sources all scripts in the 'private' folder and logs the process.

# .NOTES
# Ensure the Write-EnhancedLog function is defined before using this function for logging purposes.
# #>

# function Get-PrivateScriptPathsAndVariables {
#     param (
#         [string]$BaseDirectory
#     )

#     try {
#         $privateFolderPath = Join-Path -Path $BaseDirectory -ChildPath "private"
    
#         if (-not (Test-Path -Path $privateFolderPath)) {
#             throw "Private folder path does not exist: $privateFolderPath"
#         }

#         # Construct and return a PSCustomObject
#         return [PSCustomObject]@{
#             BaseDirectory     = $BaseDirectory
#             PrivateFolderPath = $privateFolderPath
#         }
#     }
#     catch {
#         Write-Host "Error in finding private script files: $_" -ForegroundColor Red
#         # Optionally, you could return a PSCustomObject indicating an error state
#         # return [PSCustomObject]@{ Error = $_.Exception.Message }
#     }
# }



# # Retrieve script paths and related variables
# $DotSourcinginitializationInfo = Get-PrivateScriptPathsAndVariables -BaseDirectory $PSScriptRoot

# # $DotSourcinginitializationInfo
# $DotSourcinginitializationInfo | Format-List


# function Import-ModuleWithRetry {

#     <#
# .SYNOPSIS
# Imports a PowerShell module with retries on failure.

# .DESCRIPTION
# This function attempts to import a specified PowerShell module, retrying the import process up to a specified number of times upon failure. It waits for a specified delay between retries. The function uses advanced logging to provide detailed feedback about the import process.

# .PARAMETER ModulePath
# The path to the PowerShell module file (.psm1) that should be imported.

# .PARAMETER MaxRetries
# The maximum number of retries to attempt if importing the module fails. Default is 30.

# .PARAMETER WaitTimeSeconds
# The number of seconds to wait between retry attempts. Default is 2 seconds.

# .EXAMPLE
# $modulePath = "C:\Modules\MyPowerShellModule.psm1"
# Import-ModuleWithRetry -ModulePath $modulePath

# Tries to import the module located at "C:\Modules\MyPowerShellModule.psm1", with up to 30 retries, waiting 2 seconds between each retry.

# .NOTES
# This function requires the `Write-EnhancedLog` function to be defined in the script for logging purposes.

# .LINK
# Write-EnhancedLog

# #>

#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory)]
#         [string]$ModulePath,

#         [int]$MaxRetries = 30,

#         [int]$WaitTimeSeconds = 2
#     )

#     Begin {
#         $retryCount = 0
#         $isModuleLoaded = $false
#         # Write-EnhancedLog "Starting to import module from path: $ModulePath" -Level "INFO"
#         Write-host "Starting to import module from path: $ModulePath"
#     }

#     Process {
#         while (-not $isModuleLoaded -and $retryCount -lt $MaxRetries) {
#             try {
#                 Import-Module $ModulePath -ErrorAction Stop
#                 $isModuleLoaded = $true
#                 Write-EnhancedLog "Module $ModulePath imported successfully." -Level "INFO"
#             }
#             catch {
#                 # Write-EnhancedLog "Attempt $retryCount to load module failed. Waiting $WaitTimeSeconds seconds before retrying." -Level "WARNING"
#                 Write-host "Attempt $retryCount to load module failed. Waiting $WaitTimeSeconds seconds before retrying."
#                 Start-Sleep -Seconds $WaitTimeSeconds
#             }
#             finally {
#                 $retryCount++
#             }

#             if ($retryCount -eq $MaxRetries -and -not $isModuleLoaded) {
#                 # Write-EnhancedLog "Failed to import module after $MaxRetries retries." -Level "ERROR"
#                 Write-host "Failed to import module after $MaxRetries retries."
#                 break
#             }
#         }
#     }

#     End {
#         if ($isModuleLoaded) {
#             Write-EnhancedLog "Module $ModulePath loaded successfully." -Level "INFO"
#         }
#         else {
#             # Write-EnhancedLog "Failed to load module $ModulePath within the maximum retry limit." -Level "CRITICAL"
#             Write-host "Failed to load module $ModulePath within the maximum retry limit."
#         }
#     }
# }

# Example of how to use the function
# $PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
# $LoggingmodulePath = Join-Path -Path $PSScriptRoot -ChildPath "Private\EnhancedLoggingAO\2.0.0\EnhancedLoggingAO.psm1"
# $ModuleUpdatermodulePath = Join-Path -Path $PSScriptRoot -ChildPath "Private\EnhancedModuleUpdaterAO\1.0.0\EnhancedModuleUpdaterAO.psm1"

# Call the function to import the module with retry logic
# Import-ModuleWithRetry -ModulePath $LoggingmodulePath
# Import-ModuleWithRetry -ModulePath $ModuleUpdatermodulePath
# Import-ModuleWithRetry -ModulePath 'C:\Program Files (x86)\WindowsPowerShell\Modules\PowerShellGet\PSModule.psm1'
# Import-ModuleWithRetry -ModulePath 'C:\Program Files (x86)\WindowsPowerShell\Modules\PackageManagement\PackageProviderFunctions.psm1'

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
        Write-Verbose "Starting to check and install required modules..."
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
        Write-Verbose "Completed checking and installing modules."
    }
}

# Example usage
# $modules = @('ImportExcel', 'powershell-yaml' , 'PSWriteHTML')
# Install-MissingModules -RequiredModules $modules -Verbose

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




        $modules = @('ImportExcel', 'powershell-yaml' , 'PSWriteHTML')
        Install-MissingModules -RequiredModules $modules -Verbose


        # Setup the base path without extension
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
        $basePathWithoutExtension = $basePathWithoutExtension.TrimEnd('.')
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
        Write-Verbose "Export-Data function execution completed."
    }
}