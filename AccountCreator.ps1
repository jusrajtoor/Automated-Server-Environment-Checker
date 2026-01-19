function New-UserName {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$FirstName,

        [Parameter(Mandatory)]
        [string]$LastName,

        [Parameter(Mandatory)]
        [string]$Server
    )

    try {
        [Regex]$Pattern = "\s|-|'"
        $Index = 1

        do {
            $Username = "$LastName$($FirstName.Substring(0, $Index))" -replace $Pattern, ""
            $Index++
        }
        while (
            (Get-ADUser -Filter "SamAccountName -like '$Username'" -Server $Server) -and
            ($Username -notlike "$LastName$FirstName")
        )

        if (Get-ADUser -Filter "SamAccountName -like '$Username'" -Server $Server) {
            throw "No usernames available for this account"
        } else {
            return $Username
        }
    }
    catch {
        Write-Error $_.Exception.Message
        throw
    }
}


function New-OneOffADUser {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$FirstName,

        [Parameter(Mandatory)]
        [string]$LastName,

        [Parameter()]
        [string]$Username,

        [Parameter(Mandatory)]
        [string]$Reason,

        [Parameter(Mandatory)]
        [string]$Server,

        [Parameter()]
        [datetime]$ExpirationDate,

        [Parameter()]
        [int]$PasswordLength = 15,

        [Parameter()]
        [bool]$ChangePasswordAtNextLogon = $true
    )

    try {
        if (-not $Username) {
            $Username = New-UserName -FirstName $FirstName -LastName $LastName -Server $Server
        }

        if ($ExpirationDate) {
            $Date = Get-Date -Date $ExpirationDate
        }

        $PlainTextPassword = -join (
            @('0'..'9'; 'A'..'Z'; 'a'..'z'; '!', '@', '#', '$', '%', '&') |
            Get-Random -Count $PasswordLength
        )

        $Password = ConvertTo-SecureString `
            -String $PlainTextPassword `
            -AsPlainText `
            -Force

        $ADUserParams = @{
            Name                    = $Username
            GivenName               = $FirstName
            Surname                 = $LastName
            SamAccountName          = $Username
            UserPrincipalName       = "$Username@jusrajhotmail.onmicrosoft.com"
            Description             = $Reason
            Title                   = $Reason
            Enabled                 = $true
            AccountPassword         = $Password
            Server                  = $Server
            ChangePasswordAtLogon   = $ChangePasswordAtNextLogon
        }

        if ($Date) {
            New-ADUser @ADUserParams -AccountExpirationDate $Date
        } else {
            New-ADUser @ADUserParams
        }

        Write-Output @"
User created successfully:
Name      : $FirstName $LastName
Username  : $Username
Password  : $PlainTextPassword
"@
    }
    catch {
        Write-Error $_.Exception.Message
    }
}
