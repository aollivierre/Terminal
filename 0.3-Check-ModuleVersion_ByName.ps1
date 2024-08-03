function Check-ModuleVersionStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$ModuleNames
    )

    Import-Module -Name PowerShellGet -ErrorAction SilentlyContinue

    foreach ($ModuleName in $ModuleNames) {
        try {
            $installedModule = Get-Module -ListAvailable -Name $ModuleName | Sort-Object Version -Descending | Select-Object -First 1
            $latestModule = Find-Module -Name $ModuleName -ErrorAction SilentlyContinue

            if ($installedModule -and $latestModule) {
                if ($installedModule.Version -lt $latestModule.Version) {
                    Write-Host "Module '$ModuleName' is outdated. Installed version: $($installedModule.Version). Latest version: $($latestModule.Version)." -ForegroundColor Red
                } else {
                    Write-Host "Module '$ModuleName' is up-to-date with the latest version: $($installedModule.Version)." -ForegroundColor Green
                }
            } elseif (-not $installedModule) {
                Write-Host "Module '$ModuleName' is not installed." -ForegroundColor Yellow
            } else {
                Write-Host "Unable to find '$ModuleName' in the PowerShell Gallery." -ForegroundColor Yellow
            }
        } catch {
            Write-Error "An error occurred checking module '$ModuleName': $_"
        }
    }
}


# Check-ModuleVersionStatus -ModuleNames @('Pester', 'AzureRM', 'PowerShellGet')
Check-ModuleVersionStatus -ModuleNames @('Pester')