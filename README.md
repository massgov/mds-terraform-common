# Common Terraform Modules

This repository contains common Terraform modules that are used across the Massachussetts Digital Services infrastructure.

Each module should have:

* A `README.md` describing what the module does and how to use it.
* A `main.tf` file.
* A `variables.tf` file, if it takes input variables.
* An `outputs.tf` file, if it produces outputs.

Packer
------

This repository uses Packer to build custom AMIs. To rebuild an AMI:

```bash
# Authenticate so credentials are available to packer.
aws-exec massgov
packer build packer/ecs_ssm.json
# Packer will build the AMI and output the ID.
```

Development Workflow
--------------------

These Terraform modules are used by other Terraform code.  Development happens in the `develop` branch.  Once the code is tested and stable, use the following process to make a release:

* Merge `develop` to `master`
* Update the changelog to categorize items as being in the correct release.  Commit this change directly to `master`.
* Tag a new release using Semantic versioning (breaking changes are a major release).
* Merge `master` back to `develop`

Contributing
------------

When you update a module in this repository, please update [CHANGELOG.md](./CHANGELOG.MD) with a description of the change made to each module headed under a new version tag and the release date. For example, if the current version tag is `1.0.99` and you're planning to release changes to [asg](./asg/) and [ecscluster](./ecscluster) on January 1 2025, a possible CHANGELOG line might look like

```md
## [1.0.100] - 2025-01-01

- [ASG] Replace `volume_encryption` and `volume_size` variables with `block_devices` variable
- [ECS Cluster] Add `include_ami_device_names` variable to allow importing block device specifications from AMI.
```

Once the change is squash-merged into `1.x`, tag and push the commit associated with the new version:

```sh
git tag -a 1.0.100 -m 'Updates ASG and ECS modules to allow module consumers to import block device specs' <commit hash>
git push --tags
```