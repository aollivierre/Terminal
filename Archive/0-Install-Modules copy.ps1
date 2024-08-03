function InstallAndUpdateModules {
    <#
    .SYNOPSIS
    Installs missing PowerShell modules and updates all installed modules from the PowerShell Gallery, while reporting any skipped modules.

    .DESCRIPTION
    This function checks a list of PowerShell module names, installs any that are not already installed, updates all modules installed from the PowerShell Gallery on the system, and reports modules that are skipped because they were not installed via the PowerShell Gallery.

    .PARAMETER RequiredModules
    An array of module names that you want to ensure are installed and up-to-date on the system.

    .EXAMPLE
    PS> $modules = @('ImportExcel', 'powershell-yaml', 'z', 'terminal-icons')
    PS> InstallAndUpdateModules -RequiredModules $modules

    This example installs and updates the specified modules, updates all other installed modules from the PowerShell Gallery, and lists skipped modules.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$RequiredModules
    )

    Begin {
        Write-Verbose "Starting to check, install, update, and report on required modules..."
    }

    Process {
        # Install or update specified modules
        foreach ($module in $RequiredModules) {
            $installedModule = Get-Module -ListAvailable -Name $module
            if (-not $installedModule) {
                Write-Host "Module '$module' is not installed. Attempting to install..."
                try {
                    Install-Module -Name $module -Force -Scope AllUsers
                    Write-Host "Module '$module' installed successfully."
                }
                catch {
                    Write-Error "Failed to install module '$module'. Error: $_"
                }
            } else {
                Write-Host "Module '$module' is already installed. Checking for updates..."
                try {
                    Update-Module -Name $module -Force
                    Write-Host "Module '$module' updated successfully."
                }
                catch {
                    Write-Error "Failed to update module '$module'. Error: $_"
                }
            }
        }

        # Gather all installed modules
        $allModules = Get-Module -ListAvailable

        # Filter and update modules from PowerShell Gallery
        $galleryModules = $allModules | Where-Object { $_.Path -like '*\PSGallery\*' }
        foreach ($mod in $galleryModules) {
            try {
                Update-Module -Name $mod.Name -Force
                Write-Host "Updated module '$mod.Name' successfully."
            }
            catch {
                Write-Error "Failed to update module '$mod.Name'. Error: $_"
            }
        }

        # Identify and report skipped modules
        $skippedModules = $allModules | Where-Object { $_.Path -notlike '*\PSGallery\*' }
        foreach ($mod in $skippedModules) {
            Write-Host "Skipped updating module '$mod.Name' because it was not installed from the PowerShell Gallery."
        }
    }

    End {
        Write-Verbose "Completed process of installing, updating, and reporting on modules."
    }
}

# Example usage
# $modules = @('z', 'terminal-icons')
# InstallAndUpdateModules -RequiredModules $modules -Verbose














# function Get-ModuleSource {
#     <#
#     .SYNOPSIS
#     Identifies the source from which PowerShell modules were installed.

#     .DESCRIPTION
#     The Get-ModuleSource function retrieves all installed modules and identifies their installation source, specifically determining whether they were installed from the PowerShell Gallery or elsewhere.

#     .EXAMPLE
#     PS> Get-ModuleSource

#     This example retrieves the source information for all installed modules and displays their names and origins.
#     #>

#     # [CmdletBinding()]
#     Process {
#         $allModules = Get-Module -ListAvailable

#         foreach ($module in $allModules) {
#             $source = "Unknown"
#             if ($module.Path -like '*\PSGallery\*') {
#                 $source = "PowerShell Gallery"
#             } elseif ($module.Path -like '*\WindowsPowerShell\Modules\*') {
#                 $source = "Local Modules Directory"
#             } elseif ($module.Path -like '*\Program Files\*') {
#                 $source = "Program Files"
#             }
            
#             Write-Host "Module '$($module.Name)' comes from: $source"
#         }
#     }
# }

# # Example usage
# Get-ModuleSource

