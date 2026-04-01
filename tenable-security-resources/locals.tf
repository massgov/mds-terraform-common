locals {
  # Build a unique set of instance profile names from running instances
  unique_instance_profile_names = toset(
    compact([
      for inst in values(data.aws_instance.running) :
      try(inst.iam_instance_profile, null)
    ])
  )
  # Extract unique IAM role names from the instance profiles
  unique_role_names = toset([
    for profile in values(data.aws_iam_instance_profile.by_name) :
    profile.role_name
  ])

}
