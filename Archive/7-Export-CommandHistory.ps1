# Function to ensure a directory exists
function Ensure-DirectoryExists {
    param (
        [string]$Path
    )
    try {
        if (-Not (Test-Path -Path $Path)) {
            New-Item -ItemType Directory -Path $Path | Out-Null
            Write-Host "Directory created at $Path"
        } else {
            Write-Host "Directory already exists at $Path"
        }
    } catch {
        Write-Error "Failed to ensure directory exists at $Path. Error: $_"
    }
}

# Function to get the path of the PSReadLine history file
function Get-HistoryFilePath {
    try {
        $historyFilePath = (Get-PSReadlineOption).HistorySavePath
        Write-Host "History file path: $historyFilePath"
        return $historyFilePath
    } catch {
        Write-Error "Failed to get history file path. Error: $_"
        return $null
    }
}

# Function to export history to JSON
function Export-HistoryToJson {
    param (
        [string]$HistoryFilePath,
        [string]$ExportPath
    )
    try {
        $history = Get-Content -Path $HistoryFilePath | Select-Object -Unique | ForEach-Object { [PSCustomObject]@{CommandLine = $_} }
        $history | ConvertTo-Json | Out-File -FilePath $ExportPath
        Write-Host "History exported to $ExportPath"
    } catch {
        Write-Error "Failed to export history to JSON. Error: $_"
    }
}

# Function to copy the original history file
function Copy-HistoryFile {
    param (
        [string]$SourcePath,
        [string]$DestinationPath
    )
    try {
        Copy-Item -Path $SourcePath -Destination $DestinationPath
        Write-Host "History file copied to $DestinationPath"
    } catch {
        Write-Error "Failed to copy history file from $SourcePath to $DestinationPath. Error: $_"
    }
}

# Function to import history from JSON
function Import-HistoryFromJson {
    param (
        [string]$ImportPath
    )
    try {
        if (Test-Path -Path $ImportPath) {
            $historyJson = Get-Content -Path $ImportPath -Raw
            $history = $historyJson | ConvertFrom-Json
            foreach ($entry in $history) {
                Add-History -CommandLine $entry.CommandLine
            }
            Write-Host "History imported from $ImportPath"
        } else {
            Write-Error "History file not found at $ImportPath"
        }
    } catch {
        Write-Error "Failed to import history from JSON. Error: $_"
    }
}

# # Function to validate file integrity using MD5 hash (this needs more work)
# function Validate-FileIntegrity {
#     param (
#         [string]$FilePath1,
#         [string]$FilePath2
#     )
#     try {
#         if (Test-Path -Path $FilePath1 -and Test-Path -Path $FilePath2) {
#             $hash1 = (Get-FileHash -Path $FilePath1 -Algorithm MD5).Hash
#             $hash2 = (Get-FileHash -Path $FilePath2 -Algorithm MD5).Hash
#             if ($hash1 -eq $hash2) {
#                 Write-Host "File validation successful. The files are identical."
#                 return $true
#             } else {
#                 Write-Error "File validation failed. The files are not identical."
#                 return $false
#             }
#         } else {
#             Write-Error "One or both files do not exist for validation."
#             return $false
#         }
#     } catch {
#         Write-Error "Failed to validate file integrity. Error: $_"
#         return $false
#     }
# }

# Main script to utilize the functions
function Main {
    $historyFilePath = Get-HistoryFilePath
    if ($null -eq $historyFilePath) {
        Write-Error "History file path could not be retrieved. Exiting."
        return
    }

    $exportDir = "C:\code\configs"
    $exportPath = Join-Path -Path $exportDir -ChildPath "history.json"
    $historyCopyPath = Join-Path -Path $exportDir -ChildPath "PowerShell_history.txt"

    Ensure-DirectoryExists -Path $exportDir

    if (Test-Path -Path $historyFilePath) {
        Export-HistoryToJson -HistoryFilePath $historyFilePath -ExportPath $exportPath
        Copy-HistoryFile -SourcePath $historyFilePath -DestinationPath $historyCopyPath

        # The hash validation needs more work
        # $validationResult = Validate-FileIntegrity -FilePath1 $historyFilePath -FilePath2 $historyCopyPath
        # if ($validationResult) {
            # Import-HistoryFromJson -ImportPath $exportPath
        # } else {
        #     Write-Error "File validation failed. Import aborted."
        # }
    } else {
        Write-Error "History file not found at $historyFilePath"
    }
}

# Run the main function
Main



# $hash1 = (Get-FileHash -Path "C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" -Algorithm MD5).Hash; $hash2 = (Get-FileHash -Path "C:\code\configs\PowerShell_history.txt" -Algorithm MD5).Hash; if ($hash1 -eq $hash2) { "Files are identical" } else { "Files are not identical" }