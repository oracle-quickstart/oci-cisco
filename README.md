# oci-cisco

This is a Terraform module that deploys Cisco solutions on [Oracle Cloud Infrastructure (OCI)](https://cloud.oracle.com/en_US/cloud-infrastructure). It is developed jointly by Oracle and Cisco.

The [Oracle Cloud Infrastructure (OCI) Quick Start](https://github.com/oracle?q=quickstart) is a collection of examples that allow OCI users to get a quick start deploying advanced infrastructure on OCI. The oci-cisco repository contains the initial templates that can be used for accelerating deployment of Cisco solutions from local Terraform CLI and OCI Resource Manager.

This repo is under active development.  Building open source software is a community effort.  We're excited to engage with the community building this.

## How this project is organized

This project contains multiple solutions. Each solution folder is structured in at least 3 modules:

- **solution-folder**: launch a simple VM that subscribes to a Marketplace Image running from Terraform CLI.
- **solution-folder/build-orm**: Package cisco template in OCI [Resource Manager Stack](https://docs.cloud.oracle.com/iaas/Content/ResourceManager/Tasks/managingstacksandjobs.htm) format.
- **solution-folder/terraform-modules**: Contains a list of re-usable terraform modules (if any) for managing infrastructure resources like vcn, subnets, security, etc.

## Current Solutions 

This project includes below solutions supported: 
 
- **Cisco Network Load Balancer - Sandwich Topology** : [Cisco-oci-nlb-sandwich-topology](nlb-use-case) this allows end user to deploy Cisco solutions in hub and spoke architecture. 

## How to use these templates

You can easily use these templates pointing to the Images published in the Oracle Cloud Infrastructure Marketplace. To get it started, navigate to the solution folder and check individual README.md file. 
