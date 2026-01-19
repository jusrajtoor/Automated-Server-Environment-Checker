Import-Module C:\Scripts\SendEmail\MailModule.psm1

# Mail credentials
$MailAccount = Import-Clixml -Path C:\Scripts\SendEmail\outlook.xml
$MailPort = 587
$MailSMTPServer = "smtp-mail.outlook.com"

$MailFrom = $MailAccount.UserName
$MailTo   = "jusrajexample@gmail.ca"

# Logging
$LogPath = "C:\Logs"
$LogFile = "AccountLockouts - $(Get-Date -Format 'yyyy-MM-dd HH-mm').csv"

# Get locked-out AD users
$LockedOutUsers = Search-ADAccount `
    -LockedOut `
    -Server "example.local"

$Export = [System.Collections.ArrayList]@()

foreach ($LockedOutUser in $LockedOutUsers) {

    $ADUser = Get-ADUser `
        -Identity $LockedOutUser.SamAccountName `
        -Server "example.local" `
        -Properties *

    $Entry = [PSCustomObject]@{
        Name                    = "$($ADUser.GivenName) $($ADUser.Surname)"
        UserName                = $ADUser.SamAccountName
        LockoutTime             = [datetime]::FromFileTime($ADUser.LockoutTime)
        LastBadPasswordAttempt  = $ADUser.LastBadPasswordAttempt
    }

    [void]$Export.Add($Entry)
}

# Export CSV if data exists
if ($Export.Count -gt 0) {
    if (-not (Test-Path $LogPath)) {
        New-Item -ItemType Directory -Path $LogPath | Out-Null
    }

    $Export | Export-Csv `
        -Path "$LogPath\$LogFile" `
        -NoTypeInformation
}

# Email report if file exists
if (Test-Path "$LogPath\$LogFile") {

    $Subject = "Active Directory Account Lockouts"
    $Body = @"
Hi Jusraj,

Attached is the latest report of currently locked-out Active Directory accounts.

Regards,
Jusraj
"@

    Send-MailKitMessage `
        -From $MailFrom `
        -To $MailTo `
        -SMTPServer $MailSMTPServer `
        -Port $MailPort `
        -Credential $MailAccount `
        -Subject $Subject `
        -Body $Body `
        -Attachments "$LogPath\$LogFile"
}
