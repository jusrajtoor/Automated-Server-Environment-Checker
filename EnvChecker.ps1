Import-Module C:\Scripts\SendEmail\MailModule.psm1

# Mail configuration
$MailAccount     = Import-Clixml -Path C:\Scripts\SendEmail\outlook.xml
$MailPort        = 587
$MailSMTPServer  = "smtp-mail.outlook.com"
$MailFrom        = $MailAccount.UserName
$MailTo          = "jusrajexample@gmail.ca"

# Server list
$ServerListFilePath = "C:\EnvChecks\EnvCheckerList.csv"
$ServerList = Import-Csv -Path $ServerListFilePath

$Export = [System.Collections.ArrayList]@()

foreach ($Server in $ServerList) {

    $ServerName     = $Server.ServerName
    $LastStatus     = $Server.LastStatus
    $DownSince      = $Server.DownSince
    $LastDownAlert  = $Server.LastDownAlertTime
    $Alert          = $false
    $DateTime       = Get-Date

    $Connection = Test-Connection -ComputerName $ServerName -Count 1 -ErrorAction SilentlyContinue

    if ($Connection.Status -eq "Success") {

        if ($LastStatus -ne "Success") {
            $Server.DownSince = $null
            $Server.LastDownAlertTime = $null

            Write-Output "$ServerName is now online"

            $Alert   = $true
            $Subject = "$ServerName is now online!"
            $Body    = @"
<h2>$ServerName is now online</h2>
<p>$ServerName came online at $DateTime</p>
"@
        }

    } else {

        if ($LastStatus -eq "Success") {

            Write-Output "$ServerName is now offline"

            $Server.DownSince = $DateTime
            $Server.LastDownAlertTime = $DateTime

            $Alert   = $true
            $Subject = "$ServerName is now offline!"
            $Body    = @"
<h2>$ServerName is now offline</h2>
<p>$ServerName went offline at $DateTime</p>
"@

        } else {

            $DownFor = (New-TimeSpan -Start $DownSince -End $DateTime).Days
            $SinceLastDownAlert = (New-TimeSpan -Start $LastDownAlert -End $DateTime).Days

            if ($DownFor -ge 1 -and $SinceLastDownAlert -ge 1) {

                Write-Output "$ServerName is still offline ($DownFor days)"

                $Server.LastDownAlertTime = $DateTime

                $Alert   = $true
                $Subject = "$ServerName still offline ($DownFor days)"
                $Body    = @"
<h2>$ServerName still offline</h2>
<p>Offline since $DownSince ($DownFor days)</p>
"@
            }
        }
    }

    if ($Alert) {
        Send-MailKitMessage `
            -From $MailFrom `
            -To $MailTo `
            -SMTPServer $MailSMTPServer `
            -Port $MailPort `
            -Credential $MailAccount `
            -Subject $Subject `
            -Body $Body `
            -BodyAsHtml
    }

    $Server.LastStatus   = $Connection.Status
    $Server.LastCheckTime = $DateTime

    [void]$Export.Add($Server)
}

# Update server list
$Export | Export-Csv `
    -Path $ServerListFilePath `
    -NoTypeInformation

