# Fluid-Slurm-GCP (Terraform)
Copyright 2020 Fluid Numerics LLC

Create an autoscaling HPC cluster on Google Cloud Platform using Terraform infrastructure-as-code and Fluid Numerics' [fluid-slurm-gcp VM images](https://console.cloud.google.com/marketplace/details/fluid-cluster-ops/fluid-slurm-gcp)

This repository defines a terraform module for deploying an autoscaling, Slurm-based, HPC cluster on Google Cloud. This module creates
* Service accounts for the controller, login, and compute instances for your cluster
* IAM policies for service accounts, system administrators, and system users
* Controller and Login nodes

You can use this module in conjunction with other modules, like [lustre-gcp_terraform](https://github.com/FluidNumerics/lustre-gcp_terraform) to create more complete solutions.

## Getting Started
Take a look through the [`examples/`](./examples) subdirectory for existing deployment examples that leverage this module.

### Examples

* [Create a simple CentOS-7 based HPC cluster](./examples/centos-cluster)

## License
### This repository
The terraform scripts contained in this repository are licensed under a 3-Clause BSD License

### Fluid-Slurm-GCP Images
Use of the `projects/fluid-cluster-ops/global/images/fluid-slurm-gcp-*` images incur a $0.01 USD/vCPU/hour and $0.09 USD/GPU/hour usage fee on Google Cloud Platform to help Fluid Numerics support the [Marketplace solutions](https://console.cloud.google.com/marketplace/details/fluid-cluster-ops/fluid-slurm-gcp?utm_source=github&utm_medium=link&utm_campaign=v240&utm_content=terraform), this repository, and other community driven activities. [See our pricing examples documentation for more details](https://help.fluidnumerics.com/slurm-gcp/pricing). 

## How to get Support
Use of the fluid-slurm-gcp images in your deployment is subject to the [End-User-License Agreement for the fluid-slurm-gcp images](https://help.fluidnumerics.com/slurm-gcp/eula) which entitles you to basic support from Fluid Numerics. 

To obtain support from Fluid Numerics, you can
* Send a support request to fluid-slurm-gcp@fluidnumerics.com
* [Use the issue tracker to submit bugs, issues, and feature requests.](https://github.com/FluidNumerics/fluid-slurm-gcp_terraform/issues/new)

Fluid Numerics is here to make sure you are able to get up and running with your autoscaling Cloud-HPC cluster!

