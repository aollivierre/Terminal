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

Install-Module -Name EnhancedBoilerPlateAO -Scope AllUsers -Force
Install-Module -Name EnhancedLoggingAO -Scope AllUsers -Force

Write-EnhancedLog "Logging works" -Level "INFO"

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