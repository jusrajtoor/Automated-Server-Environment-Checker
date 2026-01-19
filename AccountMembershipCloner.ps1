function Copy-ADPrincipalGroupMembership {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]$SourceUserName,

        [Parameter(Mandatory)]
        [string]$TargetUserName,

        [Parameter(Mandatory)]
        [string]$Server,

        [Parameter()]
        [switch]$Replace
    )

    try {
        $SourceGroups = Get-ADPrincipalGroupMembership `
            -Identity $SourceUserName `
            -Server $Server

        $TargetGroups = Get-ADPrincipalGroupMembership `
            -Identity $TargetUserName `
            -Server $Server

        if ($SourceGroups -and $TargetGroups) {

            $CompareResults = Compare-Object `
                -ReferenceObject $SourceGroups `
                -DifferenceObject $TargetGroups `
                -Property SamAccountName

            $Adds    = $CompareResults | Where-Object SideIndicator -eq "<="
            $Removes = $CompareResults | Where-Object SideIndicator -eq "=>"

        } elseif ($SourceGroups) {
            $Adds    = $SourceGroups
            $Removes = $null

        } elseif ($TargetGroups) {
            $Adds    = $null
            $Removes = $TargetGroups
        }

        if ($Adds) {
            foreach ($Add in $Adds) {
                Write-Debug "Adding $TargetUserName to group $($Add.SamAccountName)"
                Add-ADGroupMember `
                    -Identity $Add.SamAccountName `
                    -Members $TargetUserName `
                    -Server $Server
            }
        }

        if ($Replace -and $Removes) {
            foreach ($Remove in $Removes) {
                Write-Debug "Removing $TargetUserName from group $($Remove.SamAccountName)"
                Remove-ADGroupMember `
                    -Identity $Remove.SamAccountName `
                    -Members $TargetUserName `
                    -Server $Server `
                    -Confirm:$false
            }
        }

    } catch {
        Write-Error $_.Exception.Message
    }
}




