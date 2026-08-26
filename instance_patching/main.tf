locals {
  patch_environments = var.patch_environments
  instance_states    = ["running"]

  excluded_container_nodes = data.aws_instances.ecs_nodes.ids

  patch_instance_ids = sort(tolist(setsubtract(
    toset(data.aws_instances.patch_candidates.ids),
    local.excluded_container_nodes
  )))

  patch_batches = {
    for index, ids in chunklist(local.patch_instance_ids, 50) :
    tostring(index) => ids
  }
}

data "aws_instances" "patch_candidates" {
  instance_state_names = local.instance_states

  filter {
    name   = "tag:environment"
    values = local.patch_environments
  }
}

data "aws_instances" "ecs_nodes" {
  instance_state_names = local.instance_states

  filter {
    name = "tag-key"

    values = [
      "AmazonECSCreated",
      "AmazonECSManaged",
      "aws:ecs:clusterName"
    ]
  }
}

resource "aws_ssm_association" "nonprod_extended_patching" {
  for_each = local.patch_batches

  association_name = "nonprod-extended-patching-${each.key}"
  name             = "AWS-RunPatchBaselineWithHooks"

  schedule_expression         = var.patch_schedule_expression
  apply_only_at_cron_interval = true

  parameters = {
    Operation              = "Install"
    RebootOption           = "RebootIfNeeded"
    PreInstallHookDocName  = aws_ssm_document.container_host_guard.name
    PostInstallHookDocName = aws_ssm_document.extended_native_updates.name
    OnExitHookDocName      = "AWS-Noop"
  }

  targets {
    key    = "InstanceIds"
    values = each.value
  }

  max_concurrency = "25%"
  max_errors      = "5%"
}

resource "aws_ssm_document" "container_host_guard" {
  name            = "NonProd-Block-Container-Host-Patching"
  document_type   = "Command"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Stop patch installation when the target appears to be an ECS or K8s worker."
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "guardLinuxContainerHosts"
        precondition = {
          StringEquals = ["platformType", "Linux"]
        }
        inputs = {
          timeoutSeconds = "60"
          runCommand = [<<-BASH
            #!/usr/bin/env bash
            set -u

            detected=""

            if [ -f /etc/ecs/ecs.config ] || [ -d /var/lib/ecs ]; then
              detected="ECS"
            fi

            if [ -d /etc/eks ] || [ -e /var/lib/kubelet/kubeconfig ]; then
              detected="$${detected:+$${detected} and }Kubernetes/EKS"
            fi

            if command -v systemctl >/dev/null 2>&1; then
              if systemctl is-active --quiet ecs 2>/dev/null; then
                detected="$${detected:+$${detected} and }ECS"
              fi
              if systemctl is-active --quiet kubelet 2>/dev/null; then
                detected="$${detected:+$${detected} and }Kubernetes/EKS"
              fi
            fi

            if [ -n "$detected" ]; then
              echo "BLOCKED: $detected worker detected. This node must be replaced through its ECS/EKS image rollout, not patched in place." >&2
              exit 42
            fi

            echo "Container-host guard passed."
          BASH
          ]
        }
      },
      {
        action = "aws:runPowerShellScript"
        name   = "guardWindowsContainerHosts"
        precondition = {
          StringEquals = ["platformType", "Windows"]
        }
        inputs = {
          timeoutSeconds = "60"
          runCommand = [<<-POWERSHELL
            $ErrorActionPreference = "Stop"

            $containerServices = @("AmazonECS", "ECS", "kubelet")
            $containerPaths = @(
              "C:\ProgramData\Amazon\ECS",
              "C:\ProgramData\Amazon\EKS",
              "C:\ProgramData\kubelet"
            )

            $detectedServices = @(
              Get-Service -Name $containerServices -ErrorAction SilentlyContinue
            )
            $detectedPaths = @(
              $containerPaths | Where-Object { Test-Path $_ }
            )

            if ($detectedServices.Count -gt 0 -or $detectedPaths.Count -gt 0) {
              throw "BLOCKED: ECS or Kubernetes/EKS worker detected. This node must be replaced through its container-host image rollout, not patched in place."
            }

            Write-Output "Container-host guard passed."
          POWERSHELL
          ]
        }
      }
    ]
  })

  tags = {
    Purpose = "Patch safety guard"
  }
}

resource "aws_ssm_document" "extended_native_updates" {
  name            = "NonProd-Extended-Native-Package-Updates"
  document_type   = "Command"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Install all non-preview updates exposed by the configured native OS package sources."
    mainSteps = [
      {
        action = "aws:runShellScript"
        name   = "updateLinuxPackages"
        precondition = {
          StringEquals = ["platformType", "Linux"]
        }
        inputs = {
          timeoutSeconds = "7200"
          runCommand = [<<-BASH
            #!/usr/bin/env bash
            # Best effort by design: a hook failure would prevent the parent
            # document from reaching its reboot step after baseline patches.
            set +e

            export DEBIAN_FRONTEND=noninteractive
            export NEEDRESTART_MODE=a

            rc=0

            if command -v dnf >/dev/null 2>&1; then
              echo "Running full DNF update (RHEL, AL2023, Rocky, Alma, Oracle, or compatible OS)."
              dnf -y upgrade --refresh || rc=$?
            elif command -v yum >/dev/null 2>&1; then
              echo "Running full YUM update (RHEL, AL2, CentOS, Oracle, or compatible OS)."
              yum -y update || rc=$?
            elif command -v apt-get >/dev/null 2>&1; then
              echo "Running full APT update (Ubuntu or Debian)."
              apt-get update || rc=$?
              if [ "$rc" -eq 0 ]; then
                apt-get -y --with-new-pkgs \
                  -o Dpkg::Options::="--force-confold" \
                  upgrade || rc=$?
              fi
            elif command -v zypper >/dev/null 2>&1; then
              echo "Running full Zypper update (SUSE)."
              zypper --non-interactive refresh || rc=$?
              if [ "$rc" -eq 0 ]; then
                zypper --non-interactive patch || rc=$?
              fi
              if [ "$rc" -eq 0 ]; then
                zypper --non-interactive update || rc=$?
              fi
            else
              echo "WARNING: No supported native package manager was found." >&2
              rc=1
            fi

            if [ "$rc" -ne 0 ]; then
              echo "WARNING: The extended Linux update pass returned exit code $rc. Baseline patching can still finish and reboot; review this command output." >&2
            else
              echo "Extended Linux update pass completed successfully."
            fi

            # Always allow AWS-RunPatchBaselineWithHooks to continue to its
            # reboot and final compliance-reporting steps.
            exit 0
          BASH
          ]
        }
      },
      {
        action = "aws:runPowerShellScript"
        name   = "updateWindowsPackages"
        precondition = {
          StringEquals = ["platformType", "Windows"]
        }
        inputs = {
          timeoutSeconds = "7200"
          runCommand = [<<-POWERSHELL
            $ErrorActionPreference = "Stop"
            $ProgressPreference = "SilentlyContinue"

            try {
              $session = New-Object -ComObject Microsoft.Update.Session
              $session.ClientApplicationID = "SSM Extended Native Package Updates"
              $searcher = $session.CreateUpdateSearcher()

              # Respect an organization-managed WSUS server. If WSUS is not
              # configured, use Microsoft Update so Microsoft application
              # updates can be discovered in addition to Windows updates.
              $windowsUpdatePolicy = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ErrorAction SilentlyContinue

              $usingWsus = $null -ne $windowsUpdatePolicy -and -not [string]::IsNullOrWhiteSpace($windowsUpdatePolicy.WUServer)

              if (-not $usingWsus) {
                try {
                  $microsoftUpdateServiceId = "7971f918-a847-4430-9279-4a52d1efe18d"
                  $serviceManager = New-Object -ComObject Microsoft.Update.ServiceManager
                  $serviceManager.ClientApplicationID = "SSM Extended Native Package Updates"
                  $null = $serviceManager.AddService2($microsoftUpdateServiceId, 7, "")
                  $searcher.ServerSelection = 3
                  $searcher.ServiceID = $microsoftUpdateServiceId
                  Write-Output "Using Microsoft Update."
                }
                catch {
                  Write-Warning "Microsoft Update registration was unavailable; continuing with the configured Windows Update source: $($_.Exception.Message)"
                }
              }
              else {
                Write-Output "Using the organization-managed WSUS source."
              }

              $searchResult = $searcher.Search("IsInstalled=0 and IsHidden=0 and Type='Software'")
              $updatesToDownload = New-Object -ComObject Microsoft.Update.UpdateColl

              for ($index = 0; $index -lt $searchResult.Updates.Count; $index++) {
                $update = $searchResult.Updates.Item($index)

                # Preview updates are intentionally excluded because they are
                # not generally appropriate for unattended fleet patching.
                if ($update.Title -match "(?i)preview") {
                  Write-Output "Skipping preview update: $($update.Title)"
                  continue
                }

                if (-not $update.EulaAccepted) {
                  $update.AcceptEula()
                }

                [void]$updatesToDownload.Add($update)
                Write-Output "Selected: $($update.Title)"
              }

              if ($updatesToDownload.Count -eq 0) {
                Write-Output "No additional non-preview Windows/Microsoft updates were found."
                exit 0
              }

              $downloader = $session.CreateUpdateDownloader()
              $downloader.Updates = $updatesToDownload
              $downloadResult = $downloader.Download()
              Write-Output "Windows Update download result code: $($downloadResult.ResultCode)"

              $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
              for ($index = 0; $index -lt $updatesToDownload.Count; $index++) {
                $update = $updatesToDownload.Item($index)
                if ($update.IsDownloaded) {
                  [void]$updatesToInstall.Add($update)
                }
                else {
                  Write-Warning "Update was not downloaded: $($update.Title)"
                }
              }

              if ($updatesToInstall.Count -eq 0) {
                Write-Warning "No selected Windows updates downloaded successfully."
                exit 0
              }

              $installer = $session.CreateUpdateInstaller()
              $installer.Updates = $updatesToInstall
              $installResult = $installer.Install()

              Write-Output "Windows Update installation result code: $($installResult.ResultCode)"
              Write-Output "Windows Update requested reboot: $($installResult.RebootRequired)"

              if ($installResult.ResultCode -notin @(2, 3)) {
                Write-Warning "One or more extended Windows updates did not install successfully. Review the update history and SSM output."
              }
            }
            catch {
              # Do not prevent the parent document from rebooting after the
              # baseline installation. The error remains visible in the log.
              Write-Warning "Extended Windows update pass failed: $($_.Exception.Message)"
            }

            exit 0
          POWERSHELL
          ]
        }
      }
    ]
  })
  tags = {
    Purpose = "Extended nonproduction patching"
  }
}
