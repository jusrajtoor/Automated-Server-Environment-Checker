# ======================================
# Backup Script
# ======================================

# Paths
$BackupLocationsFilePath = "C:\Maintenance\Directories.txt"
$StorageLocation         = "C:\Backups"
$BackupName              = "Backup $(Get-Date -Format 'yyyy-MM-dd HH-mm')"
$FullBackupPath          = Join-Path $StorageLocation $BackupName

# Create main backup directory if it doesn't exist
if (-not (Test-Path $FullBackupPath)) {
    New-Item -Path $FullBackupPath -ItemType Directory | Out-Null
}

# Load directories to back up
$BackupLocations = Get-Content -Path $BackupLocationsFilePath

foreach ($Location in $BackupLocations) {

    # Skip empty lines
    if ([string]::IsNullOrWhiteSpace($Location)) { continue }

    Write-Output "Backing up $Location"

    # Preserve drive letter structure
    $LeadingPath = $Location.Replace(':', '')

    $DestinationPath = Join-Path $FullBackupPath $LeadingPath

    if (-not (Test-Path $DestinationPath)) {
        New-Item -Path $DestinationPath -ItemType Directory | Out-Null
    }

    try {
        Get-ChildItem -Path $Location -ErrorAction Stop |
            Copy-Item `
                -Destination $DestinationPath `
                -Recurse `
                -Container `
                -Force
        Write-Output "Backup of $Location completed successfully."
    }
    catch {
        Write-Warning "Failed to backup $Location. Error: $_"
    }
}

# Compress backup
$ZipPath = "$FullBackupPath.zip"

try {
    Compress-Archive `
        -Path $FullBackupPath `
        -DestinationPath $ZipPath `
        -CompressionLevel Fastest -Force
    Write-Output "Backup compressed to $ZipPath"
}
catch {
    Write-Warning "Failed to compress backup. Error: $_"
}
