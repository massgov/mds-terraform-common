# Aurora PostgreSQL Module — Design & Roadmap

Working document for building an opinionated Aurora PostgreSQL cluster module shared across
teams. It should suit an ordinary application database as readily as a cluster holding PII or
other sensitive data, with the controls that sensitive data requires available but not
mandatory.

Delete this file before the module is released, or move the durable parts into
`README.md`.

## Table of Contents

- [Assumptions](#assumptions)
- [Design principles](#design-principles)
- [Research: what an enterprise Aurora PostgreSQL cluster needs](#research-what-an-enterprise-aurora-postgresql-cluster-needs)
  - [1. Cluster shape and engine](#1-cluster-shape-and-engine)
  - [2. High availability](#2-high-availability)
  - [3. Backups and disaster recovery](#3-backups-and-disaster-recovery)
  - [4. Encryption, secrets, and access control](#4-encryption-secrets-and-access-control)
  - [5. Audit trail](#5-audit-trail)
  - [6. Monitoring](#6-monitoring)
  - [7. Maintenance and change management](#7-maintenance-and-change-management)
  - [8. Cost controls](#8-cost-controls)
  - [9. Notes for read-heavy and reporting workloads](#9-notes-for-read-heavy-and-reporting-workloads)
- [Open decisions](#open-decisions)
- [Phased build plan](#phased-build-plan)
- [Sources](#sources)

## Assumptions

- Single region (`us-east-1`), private subnets, no public access. Most of our VPCs have
  subnets in two availability zones, so two is the baseline the module assumes.
- The cluster is reached from ECS/Fargate tasks and from a jump box, both of which
  already use the SG-to-SG accessor pattern from `rdsinstance`.
- Notifications land in Microsoft Teams via SNS and the existing `teamsalerts` module.
- New Relic is the primary observability platform; CloudWatch is the source of truth
  for metrics and logs, and `newrelic/metric-stream` + `newrelic/alert-conditions-rds`
  already exist to forward them.
- Clusters holding PII need audit trails, key custody, immutable backups, and least-privilege
  access; those controls should be available to every caller and required of none.
- Most clusters using this module are non-production and low traffic. Defaults have to be
  cheap, because whatever the module defaults to is what teams will run.

## Design principles

1. **Secure defaults, explicit opt-outs.** Encryption, deletion protection, TLS
   enforcement, and audit logging are on unless a caller deliberately turns them off.
   Security defaults are free; capacity defaults are not, so capacity is opt in.
2. **No plaintext credentials in Terraform.** The master password is always managed by
   RDS in Secrets Manager; the module never accepts a `password` variable. This was
   challenged during adoption, because a cluster with a Terraform-managed password cannot
   move onto the module without a credential rotation. Decision: hold the line, and require
   that a migrating cluster move to an RDS-managed password as a separate change first.
3. **Composable, not monolithic.** The cluster module owns cluster resources. Alerting,
   backup policy, and New Relic conditions stay in their own modules and are wired up by
   the caller, matching how `rdsinstance` + `maintenance-calendar` + `teamsalerts` work today.
4. **Feature flags with safe defaults, not a hundred required variables.** Callers should
   get a compliant cluster from ~6 inputs.
5. **Additive steps.** Each phase below should be reviewable on its own and should not
   force a replacement of the cluster created by the previous phase.

## Research: what an enterprise Aurora PostgreSQL cluster needs

### 1. Cluster shape and engine

**Version.** Aurora PostgreSQL 13.x reached end of standard support on 2026-02-28. Current
supported majors are 14–18. Default the module to **17** (mature, wide extension support,
Database Insights Advanced compatible) and let callers pin a minor. Specifying the major
only (`"17"`) is safe: the provider documents `engine_version` as able to "contain a partial
version where supported by the API", and exposes `engine_version_actual` for what AWS
resolved. A warning in mymassgov's module against partial versions came from resolving
through `data.aws_rds_engine_version`, which behaves differently — it does not apply here.

Pinning a **minor** version is the risky choice, because `auto_minor_version_upgrade` will
eventually move the cluster forward and the configured version becomes a downgrade that
cannot be applied. Rather than default `auto_minor_version_upgrade` to `false` — which would
penalise the safe major-only default to guard against a caller's choice — the module warns on
the combination.

**Storage configuration.** Two options:

| | Aurora Standard (`aurora`) | Aurora I/O-Optimized (`aurora-iopt1`) |
|---|---|---|
| Storage | ~$0.10/GB-mo | ~$0.225/GB-mo |
| I/O | ~$0.20 per million requests | included, unlimited |
| Instance price | baseline | ~30% higher |

Rule of thumb: switch to I/O-Optimized when I/O is more than ~25% of the cluster's Aurora
spend, which read-heavy clusters doing large scans tend to cross. It is also a prerequisite
for the Optimized Reads tiered cache. Switching is online and allowed once every 30 days, so
start Standard, measure `VolumeReadIOPs`/`VolumeWriteIOPs`, then flip. Make it a variable,
default `aurora`.

**Instance classes.** Default to a burstable class (`db.t4g.medium`) so a forgotten
development cluster is cheap. Production callers pick `db.r7g`/`db.r6g` (Graviton, memory
optimized). `db.r6gd`/`db.r6id` add local NVMe and enable **Aurora Optimized Reads**, which
moves temporary objects — sorts, hash joins, spilled temp tables — off the Aurora volume, and
with I/O-Optimized adds tiered caching worth up to 5x instance memory. Worth reaching for on
clusters whose working set exceeds instance memory.

**Serverless v2** is worth supporting as an instance class (`db.serverless` +
`serverlessv2_scaling_configuration`) for clusters with genuinely variable load. It is not a
good default: scale-to-zero only pauses with no open connections, so anything holding a
session keeps it billing at the serverless rate around the clock. A small burstable
provisioned instance is cheaper for the idle non-production case.

### 2. High availability

- Aurora storage is already 6-way replicated across 3 AZs; that is not something we configure.
- HA is about **instances**: at least one writer plus one reader in a different AZ. Failover is
  ~30s to a reader vs. several minutes for a single-instance cluster (which has to rebuild).
  **Opt in, not default** — most callers are non-production and a second instance doubles the
  instance bill for availability they do not need. Durability is unaffected either way.
- `promotion_tier` controls failover order (0 = highest priority). Give the intended standby
  tier 0 and secondary workload groups a higher tier so they are promoted last.
- A subnet group spanning three AZs gives Aurora more room to place a replacement instance when
  a zone is unavailable, but our VPCs generally have two, so **two is the default floor**. The
  warning catches the case that actually costs us something — a multi-instance cluster whose
  subnets are all in one zone. Warn rather than fail. Note this is about instance placement
  only: the storage volume is replicated across three AZs regardless of the subnet group.
- The built-in reader endpoint falls back to the primary when a cluster has no replicas, so a
  single-instance cluster can still use it — it just resolves to the writer.
- **Custom endpoints** (`aws_rds_cluster_endpoint`) route a heavy consumer to dedicated readers
  so its queries cannot degrade the reads the application depends on.
  Note that the built-in reader endpoint covers *every* replica and cannot be restricted, so
  isolation only holds if each reader group gets its own custom endpoint and nothing uses the
  built-in one. Endpoints must be type `READER` (API/Terraform only — the console creates
  `ANY`) so membership follows failover instead of routing reads at the new writer. Limit is
  five custom endpoints per cluster, and they are not captured in snapshots, so a restore
  runbook has to recreate them. The trade-off against the built-in endpoint: a `READER` custom
  endpoint accepts only replicas, so it has no members when a group's last replica is promoted.
- **RDS Proxy** pools connections and holds client connections open across failover, cutting
  observed failover time. Caveats: extra cost, and session pinning with certain PostgreSQL
  features (prepared statements, advisory locks, `SET`) can negate pooling. Optional, off by
  default; PgBouncer in the app tier is the alternative.
- **Aurora Global Database** gives cross-region RPO < 1s and RTO ~1 min. Out of scope for v1
  but the module should not make it hard to add.

### 3. Backups and disaster recovery

- `backup_retention_period` — Aurora supports up to 35 days of continuous PITR. Default to 35.
  Backup storage beyond the cluster volume size is billed, so this is one default worth
  revisiting if small non-production clusters make it visible on a bill.
- Separate `preferred_backup_window` and `preferred_maintenance_window`, both off-peak ET,
  and non-overlapping. `rdsinstance` uses `05:10-06:00` UTC backup and `wed:04:00-wed:05:00`
  UTC maintenance; reuse those so operators only learn one schedule.
- `copy_tags_to_snapshot = true`, `deletion_protection = true`, and a real
  `final_snapshot_identifier` (never `skip_final_snapshot = true` in prod).
Scoped to Aurora's native backups. AWS Backup plans, cross-region and cross-account copies,
Vault Lock, restore testing, and snapshot export to S3 are out of scope for this module —
account-wide backup policy belongs with the team that owns it, not in every cluster module.

All of the above is already implemented in Step 1.

### 4. Encryption, secrets, and access control

- `storage_encrypted = true` always. A **customer-managed KMS key** adds a key policy, rotation,
  and the ability to make data cryptographically unrecoverable by scheduling key deletion —
  worth it for sensitive data, unnecessary for most. Opt in via `create_kms_key`, or pass an
  existing key with `kms_key_id`. **Neither the key nor the decision to encrypt can be changed
  after the cluster is created**; switching later means restoring a snapshot into a new cluster.
- `manage_master_user_password = true` puts the master credential in Secrets Manager with
  automatic rotation and no plaintext in state. Encrypt that secret with the same CMK.
- **`rds.force_ssl = 1`** in the cluster parameter group rejects non-TLS connections. Dynamic,
  so it applies without a reboot. Pair with `ca_cert_identifier` on the instances and
  application-side `sslmode=verify-full`. Safe to default on: libpq negotiates TLS by default.
- **IAM database authentication** (`iam_database_authentication_enabled`) removes long-lived
  passwords for humans and for services that can assume a role. Tokens last 15 minutes. Free
  to leave enabled and it changes nothing until a DB role is granted `rds_iam`, so default on;
  password auth continues to work alongside it.
- No public accessibility, private subnets, and the SG-to-SG accessor pattern. Keep the
  `-accessor` security group output so callers attach it exactly like `rdsinstance`.
- **Inside the database** (out of Terraform's reach, but the module should document it):
  least-privilege roles, separate migration vs. application roles, PostgreSQL row-level
  security for tenant/PII segmentation, and masked views or the `anon` extension for lower
  environments. `pgcrypto` for column-level encryption of the most sensitive fields.

### 5. Audit trail

Two complementary mechanisms:

**pgAudit** — the workhorse. Configuration:

- `shared_preload_libraries` must include `pgaudit` (**static parameter, requires a reboot**),
  then `CREATE EXTENSION pgaudit;` in each database.
- `pgaudit.log` — comma-separated classes from `ddl, role, write, read, function, misc, all`.
  Recommended baseline: **`ddl,role,write`**. Adding `read` logs every `SELECT`, which on an
  read-heavy cluster is enormous.
- `pgaudit.role = rds_pgaudit` enables **object-level auditing**: create the `rds_pgaudit` role
  and `GRANT SELECT` on just the PII tables to it. This is the correct answer for our case —
  we get read auditing on sensitive tables without logging every read.
- `pgaudit.log_parameter = 1` captures bind parameters (useful, but note it can put PII values
  into logs — decide deliberately). `pgaudit.log_catalog = 0` cuts noise.
  `pgaudit.log_statement_once = 1` reduces volume. `pgaudit.log_relation` for per-relation entries.
- pgAudit redacts cleartext passwords, which raw `log_statement` logging does not — another
  reason to use it instead of `log_statement = all`.

**Supporting PostgreSQL logging parameters:** `log_connections`, `log_disconnections`,
`log_statement = ddl`, `log_min_duration_statement` (higher on read-heavy clusters), `log_lock_waits`,
`log_autovacuum_min_duration`, `log_temp_files`, and a `log_line_prefix` that includes user,
database, application name, and client host.

**Getting logs out:** `enabled_cloudwatch_logs_exports = ["postgresql"]`, a CloudWatch log
group with KMS encryption and a retention that satisfies the audit requirement (365 days or
more — CloudWatch defaults to never expire, which is a cost problem, so set it explicitly),
plus an export or subscription filter to S3/SIEM for long-term retention. Watch storage
consumption; AWS explicitly warns pgAudit can generate a lot of log data.

**Database Activity Streams (DAS)** is the tamper-resistant complement. Activity is pushed to
Kinesis in a unified JSON format, encrypted with KMS, and in *protected* mode a DBA cannot
disable or alter the stream — that is the separation-of-duties control an auditor will ask
about. Cost is real (Kinesis + a consumer), so treat it as an opt-in flag, likely justified
for this cluster but not for every cluster.

**CloudTrail** covers the control plane (who changed the parameter group, who took a snapshot).
Confirm the org trail already captures RDS management events.

### 6. Monitoring

- **Enhanced Monitoring** (`monitoring_interval = 30`, plus an IAM role with
  `AmazonRDSEnhancedMonitoringRole`) gives OS-level metrics at higher resolution than
  CloudWatch's 60s instance metrics.
- **CloudWatch Database Insights.** Performance Insights reaches end of life **2026-06-30**;
  clusters not upgraded fall back to Database Insights *Standard* (7 days of counter metrics).
  **Advanced** mode retains 15 months and adds query execution plan capture for Aurora
  PostgreSQL, which is worth paying for on any cluster being actively tuned. Requires 14.10/15.5+.
  Set `database_insights_mode = "advanced"` (which forces `performance_insights_enabled = true`
  and a 465-day retention).
- **Alarms worth having** (SNS → Teams):
  - `CPUUtilization` sustained high
  - `FreeableMemory` low
  - `DatabaseConnections` approaching `max_connections`
  - `DBLoad` / `DBLoadNonCPU` above vCPU count (the real saturation signal)
  - **`FreeLocalStorage` low — the one that bites read-heavy workloads**, since big sorts and hash
    joins spill to local storage and exhausting it kills the instance
  - `AuroraReplicaLag`
  - `Deadlocks`
  - `ReadLatency` / `WriteLatency`
  - `VolumeBytesUsed` growth rate (cost and capacity)
  - `EngineUptime` dropping (unplanned restart)
  - `BufferCacheHitRatio` below ~99%
  - `ACUUtilization` if any Serverless v2 instances exist
- Alarms should be per-instance for instance metrics and per-cluster for volume metrics, and
  should cover readers, not just the writer.
- **New Relic**: rather than duplicating, forward via the existing metric stream and reuse
  `newrelic/alert-conditions-rds`. The module should output the identifiers those conditions
  need. Decide whether CloudWatch alarms or New Relic conditions are authoritative so we don't
  double-page.
- Log-based detections using the existing `cloudwatch-metrics` module: failed authentication
  attempts, `rds.force_ssl` rejections, DDL outside a change window, access to PII tables by
  unexpected roles.

### 7. Maintenance and change management

- `auto_minor_version_upgrade = true` with a defined maintenance window; `allow_major_version_upgrade = false`
  so a major version is never applied by accident.
- **Pending maintenance actions have no native push notification.** RDS event subscriptions fire
  when maintenance *happens*, not when it becomes *pending*; the AWS Health Dashboard only shows
  7 days by default. The AWS-recommended pattern is EventBridge Scheduler → Lambda →
  `DescribePendingMaintenanceActions` → SNS. We already have the `lambda`, `teamsalerts`, and
  `maintenance-calendar` modules to build this from, and `maintenance-calendar` is the natural
  home so it covers every RDS resource in the account rather than only this cluster.
- **RDS event subscriptions** (`aws_rds_cluster_event_subscription` for `db-cluster` plus
  `aws_db_event_subscription` for `db-instance` and `db-parameter-group`) with categories
  `failover`, `failure`, `maintenance`, `notification`, `configuration change`, `deletion`,
  `low storage`. Cheap and high signal — the failover notification alone is worth it.
- **Major version upgrades** should use **Blue/Green deployments**: AWS reports ~30 seconds of
  downtime vs. ~1 hour for an in-place `pg_upgrade`. Caveat for us: Terraform's `blue_green_update`
  block only exists on `aws_db_instance`, not on `aws_rds_cluster`, so this is an out-of-band
  runbook (create B/G, switch over, then reconcile the engine version in Terraform). Document it.
- **In-place major upgrades need an instance parameter group on the target family**, wired
  through `db_instance_parameter_group_name` on the cluster. The provider documents that
  argument as "only valid in combination with the `allow_major_version_upgrade` parameter",
  and a PG15 to PG17 upgrade on mymassgov failed until it was supplied. It must be a real
  resource reference, not a literal name, or there is no dependency edge and Terraform
  attempts the cluster modification before the group exists. Until Step 5 lands,
  `allow_major_version_upgrade` is hardcoded to `false` rather than exposed, so nobody sets it
  and assumes it works. When Step 5 does land, note that the cluster-level
  `db_instance_parameter_group_name` is consulted only during the upgrade, while per-group
  tuning uses `db_parameter_group_name` on each instance; both must be on the target family.
- **`apply_method` on a hardcoded parameter must be `pending-reboot`.** Setting `immediate` on
  a parameter whose value never changes produces a permanent, unresolvable diff: AWS only
  persists a new `apply_method` when the parameter's *value* also changes, so the config can
  never converge. Confirmed on two environments, and
  [#22857](https://github.com/hashicorp/terraform-provider-aws/issues/22857) was closed as an
  API limitation rather than fixed. This is not about the parameter being static —
  `rds.force_ssl` is dynamic in `aurora-postgresql17`. It applies to every parameter the module
  hardcodes, which matters most in Step 4.
- Static parameter changes require a reboot; the module should be explicit about which
  parameters are static (`shared_preload_libraries`, `rds.force_ssl` is dynamic, most
  `pgaudit.*` are dynamic) and should not set `apply_immediately = true` by default.
- **Security groups need `name_prefix` plus `create_before_destroy`.** `name` and `description`
  both force replacement, and a security group cannot be deleted while anything references it.
  `create_before_destroy` alone is not enough: security group names are unique per VPC, so the
  replacement collides with the original it is meant to replace. `name_prefix` lets the two
  coexist. Note this only helps within this module's state — a consumer in another state that
  attached the accessor group still pins it by ID until they re-apply.

### 8. Cost controls

- Graviton instance classes.
- Reserved Instances once the shape is stable (they cover Optimized Reads classes too).
- Serverless v2 for non-prod, and `aws_rds_cluster` can be stopped for up to 7 days in dev.
- Revisit Standard vs. I/O-Optimized after a month of real I/O metrics.
- Explicit CloudWatch log retention — audit logs at "never expire" get expensive fast.
- Snapshot export to S3 + lifecycle to Glacier for anything older than the PITR window.

### 9. Notes for read-heavy and reporting workloads

Not every cluster needs these, but they shape what the module has to support.

- Aurora PostgreSQL is a row-store engine. It handles moderate analytical work well, especially
  with Optimized Reads, but it is not columnar — teams running genuinely large aggregations
  should sanity-check Redshift or Athena-over-Parquet against it. Not a module concern, but it
  affects how far callers should push a single cluster.
- Reader instances often want different parameters than the writer: higher `work_mem`,
  `max_parallel_workers_per_gather`, `effective_cache_size`, and a longer `statement_timeout`.
  This is the main argument for **per-group instance parameter groups** in Step 4.
- `FreeLocalStorage` alarms and `log_temp_files` are how spilled queries get found; local
  storage is fixed by instance class and exhausting it takes the instance down.
- Aurora **parallel query** is MySQL-only; do not plan around it for PostgreSQL.

## Open decisions

1. How much of the later steps should be on by default versus opt in. Audit logging and
   enhanced monitoring both cost money on every cluster that enables them, and the same
   argument that made HA opt in applies. A single `sensitive_data` or `production` flag that
   raises several defaults together may be better than a flag per feature.
2. Is Database Activity Streams required for any of our datasets, or is pgAudit + CloudTrail
   sufficient? (Drives cost and a Kinesis consumer.)
3. CloudWatch alarms vs. New Relic conditions as the authoritative alerting path.
4. Should `create_kms_key` default to `true`? It costs about $1/month, but the storage key
   cannot be changed after creation, so a caller who defaults to `aws/rds` and later needs a
   CMK has to rebuild the cluster from a snapshot.
5. Tightening the KMS key policy. The module writes out the AWS default (root gets `kms:*`,
   authorization delegated to IAM), which means a CMK currently buys rotation, distinct
   CloudTrail attribution, and crypto-shredding — but not least-privilege isolation. A
   restricted policy needs `kms:ViaService`, `kms:CreateGrant` with `kms:GrantIsForAWSResource`,
   and Secrets Manager access handled correctly, and dropping root access is unrecoverable
   without AWS Support. Add a `kms_key_policy` override variable when we take this on.
6. Audit log retention period required by EOTSS policy.
7. Does the pending-maintenance notifier belong in this module or in `maintenance-calendar`?
   (Recommend `maintenance-calendar`.)
8. Should `deletion_protection` stay on by default given how many callers are non-production
   and get torn down?

## Phased build plan

Each step is a reviewable increment. Steps 2+ should be additive and must not force a
cluster replacement.

| Step | Scope | Notes |
|---|---|---|
| **1** | **Core cluster** — `aws_rds_cluster`, `aws_rds_cluster_instance`, subnet group, DB security group, accessor security group, outputs. | Done. Encrypted with the default RDS key, master password in Secrets Manager, deletion protection on. |
| **2** | **High availability** — instance groups, per-group instance class and `promotion_tier`, custom reader endpoints, AZ coverage and instance count checks. | Done. Instances moved from `count` to `for_each` so groups resize independently. |
| **3** | **Encryption and authentication** — optional KMS CMK for storage and the master secret, cluster parameter group enforcing `rds.force_ssl`, IAM database authentication, `ca_cert_identifier`. | Done. The storage key cannot change later — land before real data. |
| 4 | Parameter groups proper — PostgreSQL logging parameters, per-group instance parameter groups, static vs dynamic handling. | Extends the parameter group created in Step 3. |
| 5 | In-place major version upgrades — instance parameter group on the target family, `db_instance_parameter_group_name` on the cluster, reintroduce `allow_major_version_upgrade`. | Depends on Step 4. See below. |
| 6 | pgAudit — `shared_preload_libraries`, `pgaudit.*`, `rds_pgaudit` role docs, `enabled_cloudwatch_logs_exports`, log group with retention and KMS. | Object-level auditing on sensitive tables. |
| 7 | Monitoring — Enhanced Monitoring role, Database Insights Advanced, CloudWatch alarms, SNS wiring, New Relic outputs. | |
| 8 | RDS event subscriptions; pending-maintenance notifier (likely a `maintenance-calendar` change). | |
| 9 | Scale and performance — Serverless v2 instance groups, optional RDS Proxy. | |
| 10 | Optional hardening — Database Activity Streams, Aurora Global Database. | Only if the risk assessment calls for it. |

Deliberately excluded:

- **Backup policy beyond Aurora's native backups** — AWS Backup plans, cross-region and
  cross-account copies, Vault Lock, restore testing, snapshot export to S3.
- **Read replica autoscaling** (`aws_appautoscaling_target` on `rds:cluster:ReadReplicaCount`).
  Replicas it creates are not in Terraform state, so it conflicts with managing instances
  explicitly. A Serverless v2 instance group is the better answer for variable read capacity.

## Sources

- [Using pgAudit to log database activity — Amazon Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.pgaudit.html)
- [Reference for the pgAudit extension — Amazon Aurora](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Appendix.PostgreSQL.CommonDBATasks.pgaudit.reference.html)
- [Part 2: Audit Aurora PostgreSQL databases using Database Activity Streams and pgAudit — AWS Database Blog](https://aws.amazon.com/blogs/database/part-2-audit-aurora-postgresql-databases-using-database-activity-streams-and-pgaudit/)
- [Set up notifications for Amazon RDS pending maintenance actions — AWS Database Blog](https://aws.amazon.com/blogs/database/set-up-notifications-for-amazon-rds-pending-maintenance-actions/)
- [CloudWatch Database Insights — Amazon CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Database-Insights.html)
- [AWS Performance Insights deprecation and Database Insights comparison — pganalyze](https://pganalyze.com/blog/aws-performance-insights-deprecation-database-insights-comparison)
- [CloudWatch provides execution plan capture for Aurora PostgreSQL](https://aws.amazon.com/about-aws/whats-new/2025/01/cloudwatch-execution-plan-capture-aurora-postgresql)
- [Improving query performance for Aurora PostgreSQL with Aurora Optimized Reads](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.optimized.reads.html)
- [Aurora I/O-Optimized vs Standard: Which Is Cheaper — CloudFix](https://cloudfix.com/blog/aurora-io-optimized-vs-standard/)
- [How Wiz achieved near-zero downtime for Aurora PostgreSQL major version upgrades using Blue/Green Deployments](https://aws.amazon.com/blogs/database/how-wiz-achieved-near-zero-downtime-for-amazon-aurora-postgresql-major-version-upgrades-at-scale-using-aurora-blue-green-deployments/)
- [Amazon Aurora PostgreSQL 13.x end of standard support is February 28, 2026](https://repost.aws/articles/ARxQSsnCAlS6OhFm7M10vwjA/announcement-amazon-aurora-postgresql-13-x-end-of-standard-support-is-february-28-2026)
- [Recommended CloudWatch alarms for Aurora Serverless v2 PostgreSQL — AWS re:Post](https://repost.aws/questions/QUVDUzf3SYSWi_Al-ZAeR0rw/what-are-recommended-alarms-in-cloudwatch-for-amazon-aurora-serverless-v2-for-postgresql)
- [Designing Ransomware-Resilient Backups with AWS Backup Vault Lock](https://medium.com/@praveenvallepu/designing-ransomware-resilient-backups-with-aws-backup-vault-lock-31b47deb689d)
- [Operational Best Practices for RDS PostgreSQL and Aurora PostgreSQL (AWS)](https://pages.awscloud.com/rs/112-TZM-766/images/Operational%20Best%20Practices%20for%20RDS%20PostgreSQL%20and%20Aurora%20PostgreSQL.pdf)
- [Set up notifications for Amazon RDS or Amazon Redshift maintenance windows — AWS re:Post](https://www.repost.aws/knowledge-center/notification-maintenance-rds-redshift)
