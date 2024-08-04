#Unique Tracking ID: 275d6fc2-003c-4da0-9e66-16cfa045f901, Timestamp: 2024-03-20 12:25:26
# Read configuration from the JSON file
# $configPath = Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath "..") -ChildPath "config.json"
# $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

function Write-EnhancedLog {
    param (
        [string]$Message,
        [string]$Level = 'INFO',
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::White,
        [string]$CSVFilePath_1001 = "$scriptPath_1001\exports\CSV\$(Get-Date -Format 'yyyy-MM-dd')-Log.csv",
        [string]$CentralCSVFilePath = "$scriptPath_1001\exports\CSV\$Filename.csv",
        [switch]$UseModule = $false,
        [string]$Caller = (Get-PSCallStack)[0].Command
    )
    
    # Add timestamp, computer name, and log level to the message
    $formattedMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $($env:COMPUTERNAME): [$Level] [$Caller] $Message"
    
    # Set foreground color based on log level
    switch ($Level) {
        'DEBUG' { $ForegroundColor = [ConsoleColor]::Gray } # Added level
        'INFO' { $ForegroundColor = [ConsoleColor]::Green }
        'NOTICE' { $ForegroundColor = [ConsoleColor]::Cyan } # Added level
        'WARNING' { $ForegroundColor = [ConsoleColor]::Yellow }
        'ERROR' { $ForegroundColor = [ConsoleColor]::Red }
        'CRITICAL' { $ForegroundColor = [ConsoleColor]::Magenta } # Added level
        default { $ForegroundColor = [ConsoleColor]::White } # Default case for unknown levels
    }
    
    # Write the message with the specified colors
    $currentForegroundColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = $ForegroundColor
    Write-Host $formattedMessage
    $Host.UI.RawUI.ForegroundColor = $currentForegroundColor
    
    # Append to CSV file
    # AppendCSVLog -Message $formattedMessage -CSVFilePath $CSVFilePath_1001
    # AppendCSVLog -Message $formattedMessage -CSVFilePath $CentralCSVFilePath
    
    # Potential place for Write to event log (optional)
    # Depending on how you implement `Write-CustomEventLog`, you might want to handle it differently for various levels.


    # Write to event log (optional)
    # Write-CustomEventLog -EventMessage $formattedMessage -Level $Level

    
    # Adjust this line in your script where you call the function
    # Write-EventLogMessage -LogName $LogName -EventSource $EventSource -Message $formattedMessage -EventID 1001
}

# Note: Make sure the `AppendCSVLog` function is defined in your script or module.
# It should handle the CSV file appending logic.

    
#################################################################################################################################
################################################# END LOGGING ###################################################################
#################################################################################################################################
