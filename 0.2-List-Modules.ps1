function Get-ModuleDetails {
    <#
    .SYNOPSIS
    Retrieves detailed information about all installed PowerShell modules and exports to a grid view.

    .DESCRIPTION
    This function fetches detailed information about each module installed via PowerShellGet and manually extracts data from module manifests when PowerShellGet data is unavailable. Results are displayed in a grid view.

    .EXAMPLE
    PS> Get-ModuleDetails
    #>

    # [CmdletBinding()]
    Begin {
        # Initialize a list to store module details using System.Collections.Generic.List for better performance
        $moduleDetails = New-Object System.Collections.Generic.List[psobject]
    }

    Process {
        $allModules = Get-Module -ListAvailable

        foreach ($module in $allModules) {
            $props = $null
            try {
                $installedModule = Get-InstalledModule -Name $module.Name -ErrorAction Stop
                $props = @{
                    Name = $installedModule.Name
                    Version = $installedModule.Version
                    RepositorySourceLocation = $installedModule.RepositorySourceLocation
                    Author = $installedModule.Author
                    AccessMode = $installedModule.AccessMode
                    ClrVersion = $installedModule.ClrVersion
                    CompanyName = $installedModule.CompanyName
                    ModuleBase = $installedModule.InstalledLocation
                    ModulePath = $installedModule.Path
                }
            }
            catch {
                $manifestData = Get-Content $module.Path | Out-String
                $props = @{
                    Name = $module.Name
                    Version = ([regex]::Match($manifestData, "(?<=ModuleVersion = ')(.*?)(?=')")).Value
                    RepositorySourceLocation = "Unknown"
                    Author = ([regex]::Match($manifestData, "(?<=Author = ')(.*?)(?=')")).Value
                    AccessMode = "Unknown"
                    ClrVersion = ([regex]::Match($manifestData, "(?<=CLRVersion = ')(.*?)(?=')")).Value
                    CompanyName = ([regex]::Match($manifestData, "(?<=CompanyName = ')(.*?)(?=')")).Value
                    ModuleBase = $module.ModuleBase
                    ModulePath = $module.Path
                }
            }
            $moduleDetails.Add((New-Object -TypeName PSObject -Property $props))
        }
    }

    End {
        $moduleDetails | Out-GridView -Title "Installed PowerShell Modules"
        Write-Host ("Total number of modules processed: " + $moduleDetails.Count)
    }
}

# Example usage
Get-ModuleDetails