# Fluid-Slurm-GCP CentOS Cluster

This deployment allows you to set up a flexible autoscaling HPC cluster with the Slurm job scheduler, based on the CentOS 7 operating system.

## Resources that are created

* Slurm Controller GCE Instance
* Slurm Login Node GCE Instance
* Slurm Controller Service Account
* Slurm Login Node Service Account
* Slurm Compute Node Service Account
* Necessary IAM Role Bindings for Slurm Users, Slurm Admins, and Service Accounts
* VPC Network, Subnets, and Firewall Rules


## Prerequisites
* Terraform (preferrably v0.14.7 or higher)
* Project Editor role on a GCP project
* GCS Bucket (for storing Terraform state)

## Getting Started

### Use GCS as your Terraform backend (Recommended)
You can configure this deployment to have a persistent terraform state stored in Google Cloud Storage. This is required if you are deploying your cluster using CI/CD workflows or if you plan to work on multiple work stations. 

1. Open `main.tf` in a text editor and uncomment the `terraform` block at the top of the file. 

2. Set the `bucket` to the name of a GCS bucket that will store your terraform state 

3. Set the `prefix` to a subdirectory in your GCS bucket where the terraform state will be stored.

For example,
```
terraform {
  backend "gcs" {
    bucket  = "fluidnumerics-tfstates"
    prefix  = "fluid-slurm-gcp-cluster"
  }
}
```

### Configure your deployment
Edit the `fluid.auto.tfvars` file to customize your deployment.

At a minimum, set the following variables :

* `cluster_name` : This is the name for your cluster and is used to prefix all resources.
* `primary_project` : The GCP Project ID where you want to deploy the cluster's login node and controller
* `primary_zone` : The GCP zone that will host the login node and controller
* `slurm_gcp_admins` : The GMail or Google workspace user or group email addresses for individuals requiring root level access on the cluster
* `slurm_gcp_users` : The GMail or Google workspace user or group email addresses for individuals requiring access to the cluster to submit jobs.
* `slurm_accounts` : A list-object that specifies Slurm account names, users belonging to those accounts, and the partitions they can submit jobs to.
* `partitions[0].machines[0].zone` : The GCP zone that will host the first partition's first machine block.

You can set the controller and login node configurations using the following variables
* `controller_machine_type` : The GCE machine type for the Slurm Controller
* `controller_disk_type` : The disk type for the controller (`pd-standard` or `pd-ssd`)
* `controller_disk_size_gb` : The disk size for the controller (in GB). By default, the controller serves `/apps/` and `/home/` over NFS to login and compute nodes.
* `login_machine_type` : The GCE machine type for the login node
* `login_disk_type` : The disk type for the login node (`pd-standard` or `pd-ssd`)
* `login_disk_size_gb` : The disk size for the login node (in GB). 

#### Custom VM Images on Compute Nodes 
To use a custom VM image for your compute nodes, you can specify the VM image self-link in the `compute_image` terraform variable. This sets the default compute image uniformly in your deployment. 

If you require multiple custom VM images, you can specify custom VM images in each of the `partition[].machine[].image` attributes.

To create a custom VM image, we recommend using the [fluidnumerics/hpc-apps-gcp](https://github.com/FluidNumerics/hpc-apps-gcp) repository as a starting point. You can start with one of the examples (e.g. [wrf](https://github.com/FluidNumerics/hpc-apps-gcp/tree/main/wrf)) and modify the `install.sh` script for your application. To bake a VM image that is compatible with fluid-slurm-gcp, use the following substitutions in the cloudbuild.yaml :
* `_SOURCE_IMAGE_FAMILY=fluid-slurm-gcp-compute-centos`
* `_SOURCE_IMAGE_PROJECT=fluid-cluster-ops`


### How to deploy
1. Initialize terraform
```
terraform init
```
2. Create a terraform plan and review.
``` 
terraform plan -out=tfplan
```
3. Deploy
```
terraform apply "tfplan" --auto-approve
```
