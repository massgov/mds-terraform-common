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

# Uncomment to send the input event to CloudWatch Logs
# Write-Host `## Environment variables
# Write-Host AWS_LAMBDA_LOG_GROUP_NAME=$Env:AWS_LAMBDA_LOG_GROUP_NAME
# Write-Host AWS_LAMBDA_LOG_STREAM_NAME=$Env:AWS_LAMBDA_LOG_STREAM_NAME
# Write-Host AWS_LAMBDA_FUNCTION_NAME=$Env:AWS_LAMBDA_FUNCTION_NAME
# Write-Host (ConvertTo-Json -InputObject $LambdaInput -Compress -Depth 5)
# Write-Host (ConvertTo-Json -InputObject $LambdaContext -Compress -Depth 5)

function rotate-accesskeys { 
    param(
        [Parameter(Mandatory = $true)]
        [String[]]$targeted_usernames ,
        [Parameter(Mandatory = $true)]
        [string]$days,
        [Parameter(Mandatory = $true)]
        [string]$region,
        [Parameter(Mandatory = $false)]
        [string]$sns_arn
    )

    Set-DefaultAWSRegion -Region $region
    
    # gets todays date minus the days specified to rotate
    $days_to_rotate = (Get-Date).AddDays(-$days)

    # rotate only the targeted users specified, other users are ignored
    if ($targeted_usernames) {
        $targets = $targeted_usernames -split ","
        $targeted_list = $targets.trim() -join "|"
        $users = (Get-IAMUsers) | where { $_.UserName -match $targeted_list }
    }

    # for each user in targeted list, get their active keys
    foreach ($user in $users) { 

        $user = ($user.UserName).trim()

        $ErroractionPreference = 'Stop'

        # get active keys first if any exist
        try {
            $getactive_key = (Get-IAMAccessKey -UserName $user | where { $_.Status -eq "Active" }) 

            # if there is no active key, continue
            if (($null -eq $getactive_key) -or ($getactive_key.count -eq 0)) { 
                Write-Host "$user has no active accesskeys, skipping $user"
                continue
            }
            # if there is one active key, get it
            if ($getactive_key.count -eq 1) { 
                $get_key = ($getactive_key | select -First 1).AccessKeyId
                $creation_date = ($getactive_key | select -First 1).CreateDate
            }
            # if there are 2 active keys, get the oldest one
            if ($getactive_key.count -eq 2) { 
                $get_key = ($getactive_key | Sort-Object -Property CreateDate | select -First 1).AccessKeyId
                $creation_date = ($getactive_key | Sort-Object -Property CreateDate | select -First 1).CreateDate
            }
        } # if an error occurs here, a statement above has failed for an unknown reason, we skip this user
        catch {
            Write-Host "an error occurred getting active keys for user $user, skipping $user"
            continue
        }

        # if the key is older than the days to rotate, rotate it..
        if (($creation_date -le $days_to_rotate)) {

            $access_key_id = ($get_key).trim()

            try { 
                # we try to deactivate the current active key first
                Update-IAMAccessKey -UserName $user -AccessKeyId $access_key_id -Status Inactive -Force &&
                # then we try to create a new key
                New-IAMAccessKey -UserName $user -Force | Tee-Object -Variable var_username
            }
            catch {
                # very likely there are 2 active keys or changes were made outside of this script
                # so we will REMOVE the OLDEST ACTIVE key and create a new one
                # We cannot make the oldest active key inactive, because we already determined this is the oldest active key
                # and if we try to make it inactive, it will fail because there are still 2 active keys
                Remove-IAMAccessKey -AccessKeyId $access_key_id -UserName $user -Force && 
                Write-Host "too many keys exist for $user , removed previous active key" &&
                New-IAMAccessKey -UserName $user -Force | Tee-Object -Variable var_username 
            }
            # new key that was created
            $keyValuePairs = @{
                "AccessKeyId"     = $var_username.AccessKeyId
                "SecretAccessKey" = $var_username.SecretAccessKey
            }

            $secret_name = $user + '_credentials'
            # try updating the secret first, if it fails we create a new secret
            Try {
                Update-SECSecret -SecretId $secret_name -SecretString (ConvertTo-Json -InputObject $keyValuePairs)
            }
            catch {
                # here we check if the secret was deleted and still pending deletion
                # if so we restore it and then update it
                $message = ($Error[0].Exception.Message)
                if ($message -match "You can't perform this operation on the secret because it was marked for deletion.") { 
                    Restore-SECSecret -SecretId $secret_name -Force &&
                    Start-Sleep 1 &&
                    Update-SECSecret -SecretId $secret_name -SecretString (ConvertTo-Json -InputObject $keyValuePairs) -Force
                }
                else {
                    # otherwise we create a new secret since it likely never existed or was deleted and no longer pending deletion
                    Write-Host "Secret did not exist for user $user, new secret created" &&
                    New-SECSecret -Name $secret_name -SecretString (ConvertTo-Json -InputObject $keyValuePairs)
                }
            }
            # get the user's ARN to create a resource policy for the secret so only that SPECIFIC user can access it
            # this only really works properly if the IAM user has access to aws console and can assume their own identity
            # otherwise admin users will be able to access the secrets for the users
            $policyarn = (Get-IAMUser -UserName $user).Arn

            # resource policy for the secret so only that user can access it (admins still can access it)
            $sec_policy = @"
 {
   "Version": "2012-10-17",
   "Statement": [
     {
       "Effect": "Allow",
       "Principal": {
         "AWS": "$policyarn"
       },
       "Action": [
         "secretsmanager:GetSecretValue",
         "secretsmanager:DescribeSecret"
       ],
       "Resource": "*"
     }
   ]
 }
"@
            # Write the resource policy for the secret so only that specified user can access it (admins still can access it)
            Write-SECResourcePolicy -ResourcePolicy $sec_policy -SecretId $secret_name &&
            Write-Host "SEC resource policy written/updated.."
        }

        elseif ([string]::IsNullOrWhitespace($creation_date)) {
            Write-Host "$user has no accesskeys or they are all Inactive"
        }
        else {
            Write-Host "$user keys are still valid and were created on $creation_date"
        }
    }
}

function publish_snstopic { 
    param(
        $region,
        $sns_arn 
    )

    $secrets = Get-SECSecretList -Region $region

    $a_list = @()
    foreach ($secret in $secrets) { 
        $changed_recently = $secret | where { (($_.LastChangedDate).Date) -eq ((Get-Date).Date) -and ($_.Name -match '_credentials$') }
        $a_list += ($changed_recently).Name
    }

    if ($a_list.count -eq 0) {
        Write-Host "no accesskeys for users were rotated today"
    }

    if ($a_list.Count -ge 1) {
        $a_list = $a_list | ForEach-Object { $_ -replace '_credentials$', '' }
        $listBlock = $a_list -join "`n"
        $rotated_message = @"
Per credential rotation policy some AWS IAM users had their AccessKeys rotated.
--------------------------------------------------------------------------------------------
New IAM User AccessKeys are in AWS SecretsManager named as '<IAM_USER>_credentials '
--------------------------------------------------------------------------------------------
IAM users that had AccessKeys rotated are:
-------------------------------------------------
$listBlock
"@
        Publish-SNSMessage -Region $region -TopicArn $sns_arn -Subject "Notification- IAM user accesskey rotated" -Message $rotated_message 
    }
} 


rotate-accesskeys -region $ENV:region -days $ENV:days -targeted_usernames $ENV:targeted_usernames -sns_arn $ENV:sns_arn &&
publish_snstopic -region $ENV:region -sns_arn $ENV:sns_arn
