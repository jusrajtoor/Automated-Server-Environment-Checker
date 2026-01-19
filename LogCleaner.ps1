$DirectoryListFilePath = "C:\Maintenance\LogDirectories.csv"

$DirectoryList = Import-Csv -Path $DirectoryListFilePath

foreach ($Directory in $DirectoryList) {

    Get-ChildItem `
        -Path $Directory.DirectoryPath `
        -Filter "$($Directory.FileName)*" |
    Where-Object {
        $_.LastWriteTime -lt (Get-Date).AddDays(-$Directory.KeepForDays)
    } |
    Remove-Item `
        -Force `
        -Confirm:$false
}
