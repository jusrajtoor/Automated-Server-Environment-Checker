# Paths
$BackupLocationsFilePath = "C:\Maintenance\Directories.txt"
$StorageLocation        = "C:\Backups"
$BackupName             = "Backup $(Get-Date -Format 'yyyy-MM-dd HH-mm')"

# Load directories to back up
$BackupLocations = Get-Content -Path $BackupLocationsFilePath

foreach ($Location in $BackupLocations) {

    Write-Output "Backing up $Location"

    # Preserve drive letter structure
    $LeadingPath = $Location.Replace(':', '')

    $DestinationPath = Join-Path $StorageLocation "$BackupName\$LeadingPath"

    if (-not (Test-Path $DestinationPath)) {
        New-Item -Path $DestinationPath -ItemType Directory | Out-Null
    }

    Get-ChildItem -Path $Location |
        Copy-Item `
            -Destination $DestinationPath `
            -Recurse `
            -Container `
            -Force
}

# Compress backup
Compress-Archive `
    -Path "$StorageLocation\$BackupName" `
    -DestinationPath "$StorageLocation\$BackupName.zip" `
    -CompressionLevel Fastest
