# Aurora PostgreSQL

Opinionated Amazon Aurora PostgreSQL cluster.

The module creates a cluster in private subnets, encrypted at rest, with the master password
managed by RDS in Secrets Manager. Access is granted with the same accessor security group
pattern used by [rdsinstance](../rdsinstance): attach the exported
`accessor_security_group_id` to anything that needs to reach the database, rather than
managing ingress rules per client.

Defaults are sized for a low traffic non-production environment: one small instance serving
both reads and writes. High availability and larger instances are opt in, so a development
cluster costs what a development cluster should.

See [ROADMAP.md](./ROADMAP.md) for the design notes and the features still to be added.

## Usage

```hcl
module "database" {
  source = "github.com/massgov/mds-terraform-common//aurora-postgresql?ref=1.0"

  name          = "myapp-dev"
  vpc_id        = data.aws_vpc.default.id
  subnet_ids    = data.aws_subnets.private.ids
  database_name = "myapp"

  tags = {
    Environment = "dev"
  }
}

resource "aws_ecs_service" "api" {
  network_configuration {
    security_groups = [module.database.accessor_security_group_id]
    # ...
  }
  # ...
}
```

Connect through `writer_endpoint` for reads and writes. On a single-instance cluster
`reader_endpoint` resolves to the same instance, so there is no benefit to using it until the
cluster has a replica.

The master credential is read from Secrets Manager, not from Terraform state:

```hcl
data "aws_secretsmanager_secret_version" "master" {
  secret_id = module.database.master_user_secret_arn
}
```

## Turning on high availability

A single-instance cluster recovers from an instance failure by rebuilding the instance, which
takes minutes. Adding a replica in a second availability zone brings that down to roughly 30
seconds. For production, raise the instance count and pick a class that fits the workload:

```hcl
module "database" {
  # ...

  instance_class = "db.r7g.large"

  instance_groups = {
    main = {
      count          = 2
      promotion_tier = 0
    }
  }
}
```

Reads can then be sent to `reader_endpoint`, which balances across the replicas. Note that
data durability does not depend on any of this — the Aurora storage volume is always
replicated six ways across three availability zones, independent of how many instances the
cluster runs.

## Instance groups

Instances are declared as named groups rather than as a flat count. A group is a set of
instances that share an instance class and a failover priority, and it is the unit that
custom endpoints attach to.

Most clusters need only the default `main` group. Groups matter when one consumer needs
different capacity than the rest, and you want its queries kept off the instances the
application depends on:

```hcl
instance_groups = {
  main = {
    count           = 2
    promotion_tier  = 0
    custom_endpoint = true
  }
  batch = {
    count           = 2
    instance_class  = "db.r7g.2xlarge"
    promotion_tier  = 15
    custom_endpoint = true
  }
}
```

| Field | Default | Meaning |
|---|---|---|
| `count` | `1` | Instances in the group. |
| `instance_class` | `var.instance_class` | Overrides the module-wide class for this group. |
| `promotion_tier` | `1` | Failover priority, `0` highest. Aurora promotes the lowest tier available and breaks ties by instance size. |
| `custom_endpoint` | `false` | Creates a reader endpoint named `<cluster>-<group>` containing only this group's instances. |

Instances are addressed by `for_each`, not `count`, so removing or resizing one group never
renumbers or replaces the instances in another. A high `promotion_tier` deprioritizes a group
during failover but does not exempt it — if every other instance is gone, one of its instances
will still be promoted.

Aurora places instances across the availability zones of the subnet group automatically, and
instance names do not track roles: after a failover `main-2` may be the writer. Resolve the
writer through `writer_endpoint`, never through an instance endpoint.

## Custom endpoints replace the reader endpoint

The built-in `reader_endpoint` balances across **every** replica in the cluster and cannot be
restricted. In the example above it would send application queries to the `batch` instances as
readily as to the `main` ones, which defeats the point of separating them. Isolation only holds
if every reader group sets `custom_endpoint = true` and nothing uses `reader_endpoint`.

Group endpoints are type `READER`, so membership follows role changes: a `main` replica
promoted during a failover leaves the `main` endpoint on its own and rejoins when it becomes a
replica again. Endpoints created by hand in the console are type `ANY` and will keep sending
read traffic to an instance after it becomes the writer.

The trade-off is that a `READER` endpoint can only contain replicas, so unlike
`reader_endpoint` it does not fall back to the writer. A group with a custom endpoint should
hold at least two instances; the module warns when one does not.

Aurora allows five custom endpoints per cluster, and they are not captured in snapshots — a
cluster restored from a snapshot needs them recreated.

## Encryption and authentication

Storage is always encrypted and the master password always lives in Secrets Manager. What is
configurable is which key does the encrypting:

```hcl
create_kms_key = true
```

That creates a customer managed key with rotation enabled, and uses it for both the storage
volume and the master password secret. Without it, both fall back to the AWS managed keys
(`aws/rds` and `aws/secretsmanager`), which is still encryption at rest. Pass `kms_key_id`
instead to reuse a key you already have.

**Decide this before the cluster is created.** Neither the encryption key nor the fact of
encryption can be changed afterwards — switching later means restoring a snapshot into a new
cluster. Scheduling the key for deletion makes the cluster permanently unreadable, which is
the point of a customer managed key and also the risk of one.

Two things are on by default because they cost nothing:

- **`force_ssl`** sets `rds.force_ssl = 1` in the cluster parameter group, rejecting non-TLS
  connections. It is a dynamic parameter, so it applies without a reboot. PostgreSQL clients
  negotiate TLS by default, so this rarely requires an application change; set
  `sslmode=verify-full` and pin the CA to get the full benefit.
- **`iam_database_authentication_enabled`** lets database roles granted `rds_iam` authenticate
  with 15-minute IAM tokens instead of a password. Enabling it changes nothing until you grant
  that role inside the database, and password authentication keeps working alongside it.

`ca_cert_identifier` pins the certificate authority for the instance server certificates.
Leaving it unset takes the current AWS default; setting it explicitly makes CA rotation a
deliberate change rather than a surprise.

## Defaults worth knowing

| Setting | Default | Why |
|---|---|---|
| `instance_groups` | one `main` group of 1 | Non-production sizing. Raise `count` to opt into failover. |
| `instance_class` | `db.t4g.medium` | Burstable and cheap. Production clusters should set a memory optimized class explicitly. |
| `backup_retention_period` | `35` | The Aurora maximum for point-in-time recovery. |
| `deletion_protection` | `true` | Deleting a cluster is not recoverable from a running instance. Set to `false` in environments that get torn down. |
| `skip_final_snapshot` | `false` | A final snapshot named `<name>-final` is taken on destroy. |
| `allow_major_version_upgrade` | `false` | Major upgrades should go through a blue/green deployment, not an in-place apply. |
| `apply_immediately` | `false` | Modifications wait for the maintenance window. |
| `storage_type` | `aurora` | Standard storage. Switch to `aurora-iopt1` once I/O is more than roughly a quarter of the cluster's spend. |
| `engine_version` | `"17"` | Major version only, so AWS selects the minor and `auto_minor_version_upgrade` can keep it current. |
| `create_kms_key` | `false` | The AWS managed keys still encrypt everything. Opt in for sensitive data, and decide before creation. |
| `force_ssl` | `true` | Rejecting plaintext connections is free and rarely breaks a client. |
| `iam_database_authentication_enabled` | `true` | Inert until a database role is granted `rds_iam`. |

## Warnings

The module emits Terraform warnings, not errors, for configurations that undercut their own
intent:

- A cluster with more than one instance whose subnets cover fewer than
  `minimum_availability_zones` (default 2) distinct zones, which would put every instance in
  one zone. Raise the variable on clusters deployed into a VPC with three availability zones.
- An instance group that exposes a custom endpoint but holds a single instance.
- Both `create_kms_key` and `kms_key_id` set, where the created key silently wins.

A single-instance cluster does not warn — that is the intended default.

## Not yet included

PostgreSQL logging parameters, per-group instance parameter groups, pgAudit and log exports,
enhanced monitoring and alarms, and RDS event subscriptions are planned follow-on steps. See
[ROADMAP.md](./ROADMAP.md).
