lImport-Module C:\Scripts\SendEmail\MailModule.psm1

$MailAccount = Import-Clixml -Path C:\Scripts\SendEmail\outlook.xml
$MailPort = 587
$MailSMTPServer = "smtp-mail.outlook.com"

$MailFrom = $MailAccount.UserName
$MailTo   = "jusrajexample@gmail.ca"

$HowManyDaysBeforeNotify = 14


$User = Get-ADUser `
    -Identity "jusraj" `
    -Properties * `
    -Server "example.local"   

if ($User -and $User.Enabled -and !$User.PasswordNeverExpires -and !$User.PasswordExpired) {

    $Name = "Jusraj"
    $Email = "jusrajexample@gmail.ca"

    $PasswordSetOn = $User.PasswordLastSet

    $PasswordPolicy = Get-ADUserResultantPasswordPolicy `
        -Identity $User.SamAccountName `
        -Server "example.local"

    if ($PasswordPolicy) {
        $MaxPasswordAge = $PasswordPolicy.MaxPasswordAge
    } else {
        $MaxPasswordAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge
    }

    $ExpiryDate = $PasswordSetOn + $MaxPasswordAge
    $Today = Get-Date
    $DaysLeft = (New-TimeSpan -Start $Today -End $ExpiryDate).Days

    if ($DaysLeft -le $HowManyDaysBeforeNotify) {

        if ($DaysLeft -ge 1) {
            $CustomMessage = "in $DaysLeft days"
        } else {
            $CustomMessage = "today"
        }

        $Subject = "Your password expires $CustomMessage"

        $Body = @"
<p>Hi Jusraj,</p>
<p>Your password expires <strong>$CustomMessage</strong>.</p>
<p>Please update your password to avoid any interruption.</p>
<p>Thanks,<br/>Jusraj</p>
"@

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
}

