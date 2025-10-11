#if you already have a terraform .tfvars for doing plan and applies, add these to it and delete this file.

#Days till key is rotated at
days_to_rotate = 90

#Amount of Days Since current Active Accesskey creation date (to remove inactive key. default is 15)
days_to_remove_inactive = 15

#number of days before an inactive key is removed to send a warning notification
days_warning_before_inactive = 7

#how often the eventbridge rule triggers outdated accesskey checks
event_frequency = "rate(1 day)"

#targeted_usernames are for iam users we are automating credential rotation for.
#each targeted_usernames needs to be wrapped in quotes and seperated by a comma with a space! just like this --> i.e ["freddy.automated_pipeline", "another.monitoringtool", "some_automated_outdated_app_user"]
targeted_usernames = ["random_user_1", "random_user_5", "random_user_9", "random_user_10"]

#email you want alerts sent to, comment out if N/A (comma seperation wrapped in quotes)
sns_alert_emails = ["dl_email@email.com"]
