<#      
.NOTES
#===========================================================================  
# Script:  
# Created With: 
# Author:  
# Date: 
# Organization:  
# File Name: 
# Comments:
#===========================================================================  
.DESCRIPTION  
#>  

#region Function Add-EnvPath

# $ScriptRootDir = $PSScriptRoot.Replace("Private", "")
# $ChromeDriverBinDir = $ScriptRootDir + "bin\ChromeDriver\v79"

function Add-EnvPath {
    [CmdletBinding()]
    param (

        [Parameter(Mandatory = $true)]
        [string] $Path,

        [ValidateSet('Machine', 'User', 'Session')]
        [string] $Container = 'Session'

        #session mean temporarily
        #User or Machines means permanently

    )
    
    begin {

        $ENVPATHHASHTABLEADD = [Ordered]@{ } #*creating an empty hashtable
        $persistedPathsHashtable = [Ordered]@{ } #*creating an empty hashtable
        $containerMapping = [Ordered]@{ }
        $containerType = ""
    }
    
    process {

        try {


            #step 1 : #! This step will update the PATH VARIABLE under SYSTEM VARIABLES (Sysdm.cpl -> Advanced -> Environment Variables -> System Variables -> Path) this will modify the user/system environment variables permanently (i.e. will be persistent across shell restarts)
            if ($Container -ne 'Session') {
                $containerMapping = @{
                    Machine = [System.EnvironmentVariableTarget]::Machine
                    User    = [System.EnvironmentVariableTarget]::User
                }
                $containerType = $containerMapping[$Container]
                $MultiGetEnvironmentVariablePath = [System.Environment]::GetEnvironmentVariable('Path', $containerType) -split ';'
        
                ForEach ($SingleGetEnvironmentVariablePath in $MultiGetEnvironmentVariablePath) {
                    $persistedPathsHashtable[$SingleGetEnvironmentVariablePath] = $null #building a hashtable whose keys are all of the existing paths in the system environment variable
                }
     

                if (!($persistedPathsHashtable.Contains($Path))) {
                    Write-Host "path not found in hashtable adding it right now" -ForegroundColor green
                    $persistedPathsHashtable[$Path] = $null #add the path as a new key entry to the hashtable beside the keys that are already there
                    [System.Environment]::SetEnvironmentVariable('Path', $persistedPathsHashtable.Keys -join ';', $containerType)
                }
            }


            #step 2 : updating the EnvPath #!this will modify the session environment variables temporarily (i.e. will NOT be persistent across shell restarts)

            $MultiENVPATHSPLIT = $env:Path -split ';'
            ForEach ($SingleENVPATHSPLIT in $MultiENVPATHSPLIT) {
                $ENVPATHHASHTABLEADD[$SingleENVPATHSPLIT] = $null #* building the hashtable and adding the system env path to it
            }
       
            if (!($ENVPATHHASHTABLEADD.Contains($Path))) {
               
                $ENVPATHHASHTABLEADD[$Path] = $null #*add the path as a new key entry to the hashtable beside the keys that are already there
                $env:Path = $ENVPATHHASHTABLEADD.Keys -join ';'
            }
        }

        #$env:Path is DIFFERENT THAN [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Machine) -split ';'
    
        catch {

            Write-Host "A Terminating Error (Exception) happened" -ForegroundColor Magenta
            Write-Host "Displaying the Catch Statement ErrorCode" -ForegroundColor Yellow
            Write-host $PSItem -ForegroundColor Red
            $PSItem
            Write-host $PSItem.ScriptStackTrace -ForegroundColor Red
            
        }
        finally {
 
        }

    }
        
    end {

        
write-host "the Premanent Env VAR "
[System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Machine) -split ';'


# write-host "the new Env VAR 2 is"
# $env:Path -split ';'

# write-host "the new Env VAR 3 is" #Same result as [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Machine) -split ';'
# $Reg = "Registry::HKLM\System\CurrentControlSet\Control\Session Manager\Environment"
# (Get-ItemProperty -Path "$Reg" -Name PATH).Path -split ';'


write-host "the Temp Env VAR is" #!Same result as $env:Path -split ';
[System.Environment]::GetEnvironmentVariable("Path") -split ';'


# write-host "the new Env VAR 5 is" # This step will gather VARIABLE under USER VARIABLES (Sysdm.cpl -> Advanced -> Environment Variables -> USER Variables -> Path)
# [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::User) -split ';'

#to open the env variable window
rundll32.exe sysdm.cpl, EditEnvironmentVariables

        
    }
}

# Add-EnvPath -Path 'C:\Users\aollivierre\Downloads\postgresql-16.2-1-windows-x64-binaries\pgsql\bin' -Container 'Machine'
# Add-EnvPath -Path 'D:\Users\aollivierre\Downloads\postgresql-16.2-1-windows-x64-binaries\pgsql\bin' -Container 'Machine'
Add-EnvPath -Path 'C:\Program Files (x86)\oh-my-posh\bin' -Container 'Machine'
# Add-EnvPath -Path 'C:\banana2' -Container 'Machine'

















# PS C:\Code\CB\DB\PSQL\CaRMS> .\Add-PATH_v7.ps1
# path not found in hashtable adding it right now



# the Premanent Env VAR
# C:\Program Files\Microsoft\jdk-17.0.10.7-hotspot\bin
# C:\Windows\system32
# C:\Windows
# C:\Windows\System32\Wbem
# C:\Windows\System32\WindowsPowerShell\v1.0\
# C:\Windows\System32\OpenSSH\
# C:\Program Files (x86)\Microsoft Group Policy\Windows 11 September 2022 Update (22H2)\PolicyDefinitions\
# C:\ProgramData\chocolatey\bin
# C:\Program Files\dotnet\
# C:\Program Files\Tailscale\
# C:\Program Files\PowerShell\7\
# C:\Program Files\PuTTY\
# C:\Users\aollivierre\Downloads\postgresql-16.2-1-windows-x64-binaries\pgsql\bin



# the Temp Env VAR is
# C:\Program Files\PowerShell\7
# C:\Program Files\Microsoft\jdk-17.0.10.7-hotspot\bin
# C:\Windows\system32
# C:\Windows
# C:\Windows\System32\Wbem
# C:\Windows\System32\WindowsPowerShell\v1.0\
# C:\Windows\System32\OpenSSH\
# C:\Program Files (x86)\Microsoft Group Policy\Windows 11 September 2022 Update (22H2)\PolicyDefinitions\
# C:\ProgramData\chocolatey\bin
# C:\Program Files\dotnet\
# C:\Program Files\Tailscale\
# C:\Program Files\PowerShell\7\
# C:\Program Files\PuTTY\
# C:\Users\Admin-Abdullah\AppData\Local\Microsoft\WindowsApps

# C:\Users\aollivierre\Downloads\postgresql-16.2-1-windows-x64-binaries\pgsql\bin

