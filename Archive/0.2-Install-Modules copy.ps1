function InstallAndUpdateModules {
    <#
    .SYNOPSIS
    Installs missing PowerShell modules and updates all installed modules from the PowerShell Gallery, only if a newer version is available.

    .DESCRIPTION
    This function checks a list of PowerShell module names, installs any that are not already installed, and updates all modules installed from the PowerShell Gallery on the system, but only if there is a newer version available. It also reports modules that are skipped because they were not installed via the PowerShell Gallery.

    .PARAMETER RequiredModules
    An array of module names that you want to ensure are installed and up-to-date on the system.

    .EXAMPLE
    PS> $modules = @('ImportExcel', 'powershell-yaml', 'z', 'terminal-icons')
    PS> InstallAndUpdateModules -RequiredModules $modules

    This example installs and updates the specified modules, and updates all other installed modules from the PowerShell Gallery only if a newer version is available.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$RequiredModules
    )

    Begin {
        Write-Verbose "Starting to check, install, and report on required modules..."
        Import-Module PowerShellGet
    }

    Process {
        foreach ($module in $RequiredModules) {
            $installedModule = Get-Module -ListAvailable -Name $module | Sort-Object Version -Descending | Select-Object -First 1
            $latestModule = Find-Module -Name $module -ErrorAction SilentlyContinue

            if (-not $installedModule) {
                Write-Host "Module '$module' is not installed. Attempting to install..."
                try {
                    Install-Module -Name $module -Force -Scope AllUsers
                    Write-Host "Module '$module' installed successfully."
                }
                catch {
                    Write-Error "Failed to install module '$module'. Error: $_"
                }
            } elseif ($latestModule.Version -gt $installedModule.Version) {
                Write-Host "A newer version of module '$module' is available. Updating..."
                try {
                    Update-Module -Name $module -Force
                    Write-Host "Module '$module' updated successfully."
                }
                catch {
                    Write-Error "Failed to update module '$module'. Error: $_"
                }
            } else {
                Write-Host "Module '$module' is up-to-date."
            }
        }

        # Update other modules from the PowerShell Gallery
        $allModules = Get-Module -ListAvailable | Where-Object { $_.Path -notlike '*\System32\*' }
        foreach ($mod in $allModules) {
            $latestModule = Find-Module -Name $mod.Name -ErrorAction SilentlyContinue
            if ($latestModule -and $latestModule.Version -gt $mod.Version) {
                try {
                    Update-Module -Name $mod.Name -Force
                    Write-Host "Updated module '$mod.Name' successfully."
                }
                catch {
                    Write-Error "Failed to update module '$mod.Name'. Error: $_"
                }
            }
        }

        # Identify and report skipped modules
        $skippedModules = $allModules | Where-Object { $_.Path -like '*\System32\*' }
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













function Install-ModuleIfMissing {
    param (
        [string]$ModuleName
    )
    $installedModule = Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $installedModule) {
        Write-Host "Module '$ModuleName' is not installed. Attempting to install..."
        try {
            Install-Module -Name $ModuleName -Force -Scope AllUsers
            Write-Host "Module '$ModuleName' installed successfully."
        }
        catch {
            Write-Error "Failed to install module '$ModuleName'. Error: $_"
        }
    }
}

function Update-ModuleIfOld {
    param (
        [string]$ModuleName
    )
    $installedModule = Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object -First 1
    $latestModule = Find-Module -Name $ModuleName -ErrorAction SilentlyContinue

    if ($latestModule -and $latestModule.Version -gt $installedModule.Version) {
        Write-Host "A newer version of module '$ModuleName' is available. Updating..."
        try {
            Update-Module -Name $ModuleName -Force
            Write-Host "Module '$ModuleName' updated successfully."
        }
        catch {
            Write-Error "Failed to update module '$ModuleName'. Error: $_"
        }
    } else {
        Write-Host "Module '$ModuleName' is up-to-date."
    }
}





function Update-System32Modules {
    $system32Modules = Get-Module -ListAvailable | Where-Object { $_.Path -like '*\System32\*' }
    foreach ($mod in $system32Modules) {
        Write-Host "Skipped updating module '$mod.Name' because it is a System32 module."
    }
}





function Update-MicrosoftGraphModules {
    $graphModules = @('Microsoft.Graph', 'Microsoft.Graph.Auth')
    foreach ($mod in $graphModules) {
        Update-ModuleIfOld -ModuleName $mod
    }
}





function Update-PesterModule {
    Update-ModuleIfOld -ModuleName 'Pester'
}




# To update Microsoft.Graph modules
Update-MicrosoftGraphModules

# To update System32 modules
Update-System32Modules

# To update the Pester module
Update-PesterModule



