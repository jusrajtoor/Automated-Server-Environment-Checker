Import-Module C:\Scripts\SendEmail\MailModule.psm1

# Mail configuration
$MailAccount    = Import-Clixml -Path C:\Scripts\SendEmail\outlook.xml
$MailPort       = 587
$MailSMTPServer = "smtp-mail.outlook.com"
$MailFrom       = $MailAccount.UserName
$MailTo         = "jusraj@hotmail.ca"

# Paths
$ServicesFilePath = "C:\Maintenance\Services.csv"
$LogPath          = "C:\Logs"
$LogFile          = "Services-$(Get-Date -Format 'yyyy-MM-dd HH-mm').txt"

# Load service configuration
$ServicesList = Import-Csv -Path $ServicesFilePath

foreach ($Service in $ServicesList) {

    $CurrentServiceStatus = (Get-Service -Name $Service.Name).Status

    if ($Service.Status -ne $CurrentServiceStatus) {

        $Log = "Service '$($Service.Name)' is currently $CurrentServiceStatus, should be $($Service.Status)"
        Write-Output $Log
        Out-File -FilePath "$LogPath\$LogFile" -Append -InputObject $Log

        $Log = "Setting service '$($Service.Name)' to $($Service.Status)"
        Write-Output $Log
        Out-File -FilePath "$LogPath\$LogFile" -Append -InputObject $Log

        Set-Service -Name $Service.Name -Status $Service.Status

        $AfterServiceStatus = (Get-Service -Name $Service.Name).Status

        if ($Service.Status -eq $AfterServiceStatus) {
            $Log = "Action successful: service '$($Service.Name)' is now $AfterServiceStatus"
        } else {
            $Log = "Action failed: service '$($Service.Name)' is still $AfterServiceStatus (expected $($Service.Status))"
        }

        Write-Output $Log
        Out-File -FilePath "$LogPath\$LogFile" -Append -InputObject $Log
    }
}

# Email log if issues occurred
if (Test-Path "$LogPath\$LogFile") {

    $Subject = "$($env:COMPUTERNAME) – Service Status Remediation"
    $Body = @"
Hi Jusraj,

One or more services required remediation.
Please see the attached log for details.

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
