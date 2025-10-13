# PowerShell script file to be executed as a AWS Lambda function. 
# When executing in Lambda the following variables will be predefined.
#   $LambdaInput - A PSObject that contains the Lambda function input data.
#   $LambdaContext - An Amazon.Lambda.Core.ILambdaContext object that contains information about the currently running Lambda environment.
# The last item in the PowerShell pipeline will be returned as the result of the Lambda function.
# To include PowerShell modules with your Lambda function, like the AWS.Tools.S3 module, add a "#Requires" statement
# indicating the module and version. If using an AWS.Tools.* module the AWS.Tools.Common module is also required.
#Requires -Modules @{ModuleName='AWS.Tools.Common';ModuleVersion='4.1.318.0'}
#Requires -Modules @{ModuleName='AWS.Tools.SecretsManager';ModuleVersion='4.1.318.0'}
#Requires -Modules @{ModuleName='AWS.Tools.IdentityManagement';ModuleVersion='4.1.318.0'}
#Requires -Modules @{ModuleName='AWS.Tools.SimpleNotificationService'; ModuleVersion='4.1.318.0'}
#Requires -Modules @{ModuleName='AWS.Tools.Lambda'; ModuleVersion='4.1.318.0'}
#Requires -Modules @{ModuleName='AWS.Tools.CloudWatchLogs';ModuleVersion='4.1.318.0'}
#Requires -Modules @{ModuleName='AWS.Tools.CloudWatch';ModuleVersion='4.1.318.0'}

function check_remove_accesskeys { 

    param(
        [Parameter(Mandatory = $true)]
        [String[]]$targeted_usernames ,
        [Parameter(Mandatory = $true)]
        [string]$days_to_remove_inactive,
        [Parameter(Mandatory = $true)]
        [string]$region,
        [Parameter(Mandatory = $true)]
        [string]$accesskey_rotation_lambda_name,
        [Parameter(Mandatory = $true)]
        [string]$days_warning_before_inactive,
        [Parameter(Mandatory = $true)]
        [string]$sns_arn
    )

    if ($targeted_usernames) { 
        $targets = $targeted_usernames -split ","
        $targeted_list = $targets.trim() -join "|" 
        $users = (Get-IamUsers | Where { $_.UserName -match $targeted_list })
    }

    Set-DefaultAWSRegion -Region $region

    # gets todays date minus the days specified to remove inactive keys
    # this gives us the days ago date to compare against the active key creation date
    # in order to determine if the inactive key should be removed permenently (inactive keys are kept for $days_to_remove_inactive) 
    $days_new_key_is_active_for = (Get-Date).AddDays( - [int]$days_to_remove_inactive)

    # calculate the warning date to be used in the accesskey rotation lambda to warn user before active key is made inactive
    $date_warning_before_inactive = $days_new_key_is_active_for.AddDays( - [int]$days_warning_before_inactive)

    #for each user in targeted list, get their keys
    foreach ($user in $users) { 
        $user = ($user.UserName).trim()

        $erroractionpreference = 'Stop'
        # get all keys for the user
        $list_keys = (Get-IAMAccessKey -UserName $user)
        # get inactive key if any exist
        $inactive_key = ($list_keys | Where { $_.Status -eq "Inactive" }).AccessKeyId
        # get inactive key create date if any exist
        $inactive_create_date = ($list_keys | Where { $_.Status -eq "Inactive" }).CreateDate
        # get active key if any exist
        $active_create_date = ($list_keys | Where { $_.Status -eq "Active" }).CreateDate
        # get all active keys if any exist
        $active_key = ($list_keys | Where { $_.Status -eq "Active" }).AccessKeyId

        if (($list_keys.count -ge 1) -and ($active_create_date -le $date_warning_before_inactive) -or ($inactive_create_date -le $date_warning_before_inactive)) {
            if ($active_key.count -eq 2) { 
                $oldest_active_key = ($list_keys | Where { $_.Status -eq "Active" } | Sort-Object CreateDate | Select-Object -First 1).AccessKeyId
            }
            $warning_message = @"
-----------------WARNING: this is an AWS IAM user key deactivation/deletion notification, per rotation policy--------------------------- 
the INACTIVE accesskey or OLDEST ACTIVE accesskey (if 2 active accesskeys exist) for this user will be removed on $date_warning_before_inactive.
This leaves only the most recently created ACTIVE accesskey remaining for this user.
--------------------------------------------------------------------------------------------
IAM users that will soon have an accesskey deleted is: $user
-----Inactive accesskey pending deletion: $inactive_key 
-----------------------------------------------------------------------------------------------------------------------------------------
(if 2 active keys exist)
-----Oldest Active accesskey pending deletion: $oldest_active_key
"@
            Publish-SNSMessage -Region $region -TopicArn $sns_arn -Subject "IAM user accesskey deletion warning" -Message $warning_message 
        } 
        # if there are 2 keys, and one is inactive, and the active key was created more than $days_new_key_is_active_for days ago
        # remove the inactive key
        if (($list_keys.count -ge 2) -and ($inactive_key.count -eq 1) -and ($active_create_date -le $days_new_key_is_active_for)) {
            Remove-IAMAccessKey -AccessKeyId $inactive_key -UserName $user -Force && 
            Write-Host "It has been $days_to_remove_inactive days since ACTIVE accesskey has been created. Inactive accesskey for $user was removed."
        }
    }

    $lambda_payload = [PSCustomObject]@{
        region             = $region
        sns_arn            = $sns_arn
        days               = $days_warning_before_inactive
        targeted_usernames = $targeted_usernames
    }
    $Payload = $lambda_payload | ConvertTo-Json
    
    # invoke the accesskey rotation lambda to run checks and possibly create any needed new keys 
    # for targeted users after we have just removed the inactive key in which a current active key exists and is older than specified days
    Invoke-LMFunction -FunctionName $accesskey_rotation_lambda_name -region $region -Payload $Payload
}

check_remove_accesskeys -region $ENV:region -sns_arn $ENV:sns_arn -days_warning_before_inactive $ENV:days_warning_before_inactive -accesskey_rotation_lambda_name $ENV:accesskey_rotation_lambda_name -days_to_remove_inactive $ENV:days_to_remove_inactive -targeted_usernames $ENV:targeted_usernames
