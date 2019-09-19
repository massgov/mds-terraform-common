#!/usr/bin/env bash

yum install -y install ec2-instance-connect
systemctl is-enabled ec2-instance-connect || systemctl enable ec2-instance-connect
