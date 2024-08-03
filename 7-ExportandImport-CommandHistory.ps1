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

# Function to import history from text files and append to the existing history file
function Import-HistoryFromTextFiles {
    param (
        [string]$ImportPath
    )
    try {
        $historyFilePath = Get-HistoryFilePath
        if ($null -eq $historyFilePath) {
            Write-Error "History file path could not be retrieved. Exiting."
            return
        }

        $txtFiles = Get-ChildItem -Path $ImportPath -Recurse -Filter *.txt
        foreach ($file in $txtFiles) {
            $content = Get-Content -Path $file.FullName
            Add-Content -Path $historyFilePath -Value $content
            Write-Host "Appended contents from $file.FullName to history file"
        }
    } catch {
        Write-Error "Failed to import history from text files. Error: $_"
    }
}

# Function to create a directory structure based on hostname and timestamp
function Create-HostAndTimestampFolders {
    param (
        [string]$BasePath
    )
    try {
        $hostname = $env:COMPUTERNAME
        $timestamp = Get-Date -Format "yyyyMMddHHmmss"
        $hostFolder = Join-Path -Path $BasePath -ChildPath $hostname
        $timestampFolder = Join-Path -Path $hostFolder -ChildPath $timestamp

        Ensure-DirectoryExists -Path $hostFolder
        Ensure-DirectoryExists -Path $timestampFolder

        return $timestampFolder
    } catch {
        Write-Error "Failed to create host and timestamp folders. Error: $_"
        return $null
    }
}

# Function to prompt for path or use default
function Prompt-ForPath {
    param (
        [string]$DefaultPath
    )
    $userInput = Read-Host "Enter the path or press Enter to use the default path [$DefaultPath]"
    if ([string]::IsNullOrWhiteSpace($userInput)) {
        return $DefaultPath
    } else {
        return $userInput
    }
}

# Export logic
function Export-History {
    $defaultPath = "C:\Code\CB\Terminal\Configs\History"
    $exportBasePath = Prompt-ForPath -DefaultPath $defaultPath
    $historyFilePath = Get-HistoryFilePath
    if ($null -eq $historyFilePath) {
        Write-Error "History file path could not be retrieved. Exiting."
        return
    }

    $timestampFolder = Create-HostAndTimestampFolders -BasePath $exportBasePath
    if ($null -eq $timestampFolder) {
        Write-Error "Failed to create timestamp folder. Exiting."
        return
    }

    $exportPath = Join-Path -Path $timestampFolder -ChildPath "PowerShell_history.txt"

    if (Test-Path -Path $historyFilePath) {
        Copy-HistoryFile -SourcePath $historyFilePath -DestinationPath $exportPath
    } else {
        Write-Error "History file not found at $historyFilePath"
    }
}

# Import logic
function Import-History {
    $defaultPath = "C:\Code\CB\Terminal\Configs\History"
    $importPath = Prompt-ForPath -DefaultPath $defaultPath

    Import-HistoryFromTextFiles -ImportPath $importPath
}

# Main script to choose between export and import
function Main {
    $choice = Read-Host "Do you want to export or import history? (Enter 'export' or 'import')"
    switch ($choice) {
        'export' { Export-History }
        'import' { Import-History }
        default { Write-Error "Invalid choice. Please enter 'export' or 'import'." }
    }
}

# Run the main function
Main
