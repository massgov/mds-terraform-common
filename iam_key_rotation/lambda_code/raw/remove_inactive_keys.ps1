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
        [Parameter(Mandatory = $false)]
        [string]$accesskey_rotation_lambda_name
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
    $days_new_key_is_active_for = (Get-Date).AddDays(-$days_to_remove_inactive)

    #for each user in targeted list, get their keys
    foreach ($user in $users) { 
        $user = ($user.UserName).trim()

        $erroractionpreference = 'Stop'
        # get all keys for the user
        $list_keys = (Get-IAMAccessKey -UserName $user)
        # get inactive key if any exist
        $inactive_key = ($list_keys | Where { $_.Status -eq "Inactive" }).AccessKeyId
        # get active key if any exist
        $active_create_date = ($list_keys | Where { $_.Status -eq "Active" }).CreateDate

        # if there are 2 keys, and one is inactive, and the active key was created more than $days_to_remove_inactive days ago
        # remove the inactive key
        if (($list_keys.count -ge 2) -and ($inactive_key.count -eq 1) -and ($active_create_date -le $days_new_key_is_active_for)) {
            Remove-IAMAccessKey -AccessKeyId $inactive_key -UserName $user -Force && 
            write-host "It has been $days_to_remove_inactive days since ACTIVE accesskey has been created. Inactive accesskey for $user was removed."
        }
    }
    # invoke the accesskey rotation lambda to run checks and possibly create any needed new keys 
    # for targeted users after we have just removed the inactive key in which a current active key exists and is older than specified days
    Invoke-LMFunction -FunctionName $accesskey_rotation_lambda_name -Region $region
} 

check_remove_accesskeys -region $ENV:region -accesskey_rotation_lambda_name $ENV:accesskey_rotation_lambda_name -days_to_remove_inactive $ENV:days_to_remove_inactive -targeted_usernames $ENV:targeted_usernames
