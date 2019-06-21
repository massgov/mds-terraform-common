VPC Read Access
===============

This module **reads** existing VPCs.  It looks up the VPC id, along with the subnet ids for the public, private, and data subnets.

It depends on being able to read `Tier` tags on the subnets.