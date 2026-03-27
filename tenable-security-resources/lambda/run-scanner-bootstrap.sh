#!/bin/bash
set -euxo pipefail

LOGFILE="/var/log/scanner-bootstrap.log"
exec > >(tee -a "${LOGFILE}") 2>&1

echo "==== scanner bootstrap start ===="
date

mkdir -p /opt/scanner-bootstrap

cat >/opt/scanner-bootstrap/README.txt <<'TXT'
This instance was bootstrapped by EventBridge -> Lambda -> SSM Run Command.
TXT

if command -v dnf >/dev/null 2>&1; then
  dnf -y install jq || true
elif command -v yum >/dev/null 2>&1; then
  yum -y install jq || true
elif command -v apt-get >/dev/null 2>&1; then
  apt-get update -y || true
  apt-get install -y jq || true
fi

echo "scanner-bootstrap completed at $(date -Iseconds)" >/opt/scanner-bootstrap/status.txt

echo "==== scanner bootstrap end ===="
