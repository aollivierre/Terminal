# <#
# .SYNOPSIS
#     Script that initiates the EnhancedLoggingAO module

# .NOTES
#     Author:      Abdullah Ollivierre
#     Contact:     
#     Website:     
# #>

[CmdletBinding()]
Param()
Process {
    # Locate all the public and private function specific files and ensure they are treated as arrays
    $PublicFunctions = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "Public") -Filter "*.ps1" -ErrorAction SilentlyContinue)
    $PrivateFunctions = @(Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath "Private") -Filter "*.ps1" -ErrorAction SilentlyContinue)


    # Inside your module
    $JSONconfigPath = $env:MYMODULE_CONFIG_PATH
    if (Test-Path -Path $JSONconfigPath) {
        $config = Get-Content -Path $JSONconfigPath | ConvertFrom-Json
        # Now you can use $config.LoggingDeploymentName or other config values
    } else {
        Write-Error -Message "Config file not found at path: $JSONconfigPath"
    }


    # Debug output
    Write-Host "Public Functions: $($PublicFunctions.FullName)"
    Write-Host "Private Functions: $($PrivateFunctions.FullName)"

    # Check if there are no function files to dot-source
    if ($PublicFunctions.Count -eq 0 -and $PrivateFunctions.Count -eq 0) {
        Write-Host "No function files found to dot-source."
    } else {
        # Dot source the function files
        foreach ($FunctionFile in @($PublicFunctions + $PrivateFunctions)) {
            try {
                Write-Host "Dot-sourcing: $($FunctionFile.FullName)"
                . $FunctionFile.FullName -ErrorAction Stop
            }
            catch [System.Exception] {
                Write-Error -Message "Failed to import function '$($FunctionFile.FullName)' with error: $($_.Exception.Message)"
            }
        }
    }

    # Export all public functions by their names
    $functionNamesToExport = $PublicFunctions | ForEach-Object { $_.BaseName }
    Export-ModuleMember -Function $functionNamesToExport -Alias *
}
