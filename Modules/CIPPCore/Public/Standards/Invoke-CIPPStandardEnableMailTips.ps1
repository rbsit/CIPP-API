function Invoke-CIPPStandardEnableMailTips {
    <#
    .FUNCTIONALITY
        Internal
    .COMPONENT
        (APIName) EnableMailTips
    .SYNOPSIS
        (Label) Enable all MailTips
    .DESCRIPTION
        (Helptext) Enables all MailTips in Outlook. MailTips are the notifications Outlook and Outlook on the web shows when an email you create, meets some requirements
        (DocsDescription) Enables all MailTips in Outlook. MailTips are the notifications Outlook and Outlook on the web shows when an email you create, meets some requirements
    .NOTES
        CAT
            Exchange Standards
        TAG
            "CIS"
            "exo_mailtipsenabled"
        ADDEDCOMPONENT
            {"type":"number","name":"standards.EnableMailTips.MailTipsLargeAudienceThreshold","label":"Number of recipients to trigger the large audience MailTip (Default is 25)","placeholder":"Enter a profile name","defaultValue":25}
        IMPACT
            Low Impact
        ADDEDDATE
            2024-01-14
        POWERSHELLEQUIVALENT
            Set-OrganizationConfig
        RECOMMENDEDBY
            "CIS"
            "CIPP"
        UPDATECOMMENTBLOCK
            Run the Tools\Update-StandardsComments.ps1 script to update this comment block
    .LINK
        https://docs.cipp.app/user-documentation/tenant/standards/list-standards
    #>

    param($Tenant, $Settings)
    $TestResult = Test-CIPPStandardLicense -StandardName 'EnableMailTips' -TenantFilter $Tenant -RequiredCapabilities @('EXCHANGE_S_STANDARD', 'EXCHANGE_S_ENTERPRISE', 'EXCHANGE_LITE') #No Foundation because that does not allow powershell access

    if ($TestResult -eq $false) {
        Write-Host "We're exiting as the correct license is not present for this standard."
        return $true
    } #we're done.
    ##$Rerun -Type Standard -Tenant $Tenant -Settings $Settings 'EnableMailTips'

    $MailTipsState = New-ExoRequest -tenantid $Tenant -cmdlet 'Get-OrganizationConfig' | Select-Object MailTipsAllTipsEnabled, MailTipsExternalRecipientsTipsEnabled, MailTipsGroupMetricsEnabled, MailTipsLargeAudienceThreshold
    $StateIsCorrect = if ($MailTipsState.MailTipsAllTipsEnabled -and $MailTipsState.MailTipsExternalRecipientsTipsEnabled -and $MailTipsState.MailTipsGroupMetricsEnabled -and $MailTipsState.MailTipsLargeAudienceThreshold -eq $Settings.MailTipsLargeAudienceThreshold) { $true } else { $false }

    if ($Settings.remediate -eq $true) {

        if ($StateIsCorrect -eq $true) {
            Write-LogMessage -API 'Standards' -tenant $Tenant -message 'All MailTips are already enabled.' -sev Info
        } else {
            try {
                New-ExoRequest -useSystemMailbox $true -tenantid $Tenant -cmdlet 'Set-OrganizationConfig' -cmdParams @{ MailTipsAllTipsEnabled = $true; MailTipsExternalRecipientsTipsEnabled = $true; MailTipsGroupMetricsEnabled = $true; MailTipsLargeAudienceThreshold = $Settings.MailTipsLargeAudienceThreshold }
                Write-LogMessage -API 'Standards' -tenant $Tenant -message 'Enabled all MailTips' -sev Info
            } catch {
                $ErrorMessage = Get-NormalizedError -Message $_.Exception.Message
                Write-LogMessage -API 'Standards' -tenant $Tenant -message "Failed to enable all MailTips. Error: $ErrorMessage" -sev Error
            }
        }
    }

    if ($Settings.alert -eq $true) {

        if ($StateIsCorrect -eq $true) {
            Write-LogMessage -API 'Standards' -tenant $Tenant -message 'All MailTips are enabled' -sev Info
        } else {
            Write-StandardsAlert -message 'Not all MailTips are enabled' -object $MailTipsState -tenant $Tenant -standardName 'EnableMailTips' -standardId $Settings.standardId
            Write-LogMessage -API 'Standards' -tenant $Tenant -message 'Not all MailTips are enabled' -sev Info
        }
    }

    if ($Settings.report -eq $true) {
        $state = $StateIsCorrect ? $true : $MailTipsState
        Set-CIPPStandardsCompareField -FieldName 'standards.EnableMailTips' -FieldValue $State -Tenant $tenant
        Add-CIPPBPAField -FieldName 'MailTipsEnabled' -FieldValue $StateIsCorrect -StoreAs bool -Tenant $tenant
    }

}
