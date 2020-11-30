// Configure the Google Cloud provider
provider "google" {
 version = "3.9"
}

// ***************************************** //
// Create the service account
// Service account is created on the first controller project.
// This service account 

resource "google_service_account" "slurm_controller" {
  account_id = "fluid-slurm-gcp-controller"
  display_name = "Fluid Slurm-GCP Controller Service Account"
  project = var.controller.project
}

resource "google_service_account" "slurm_compute" {
  account_id = "fluid-slurm-gcp-compute"
  display_name = "Fluid Slurm-GCP Compute Service Account"
  project = var.controller.project
}

resource "google_service_account" "slurm_login" {
  account_id = "fluid-slurm-gcp-login"
  display_name = "Fluid Slurm-GCP Login Service Account"
  project = var.controller.project
}


// ***************************************** //
// Set IAM policies

// Set the IAM policies on the parent folder that houses the slurm-gcp deployment
resource "google_folder_iam_policy" "slurm_gcp_folder_policy" {
  folder = var.parent_folder
  policy_data = data.google_iam_policy.slurm_gcp_iam.policy_data
}

data "google_iam_policy" "slurm_gcp_iam" {
  binding {
    role = "roles/compute.admin"
    members = flatten(["serviceAccount:${google_service_account.slurm_controller.email}",var.slurm_gcp_admins])
  }

  binding {
    role = "roles/cloudsql.admin"
    members = flatten(["serviceAccount:${google_service_account.slurm_controller.email}",var.slurm_gcp_admins])
  }
  binding {
    role = "roles/storage.admin"
    members = flatten(["serviceAccount:${google_service_account.slurm_compute.email}","serviceAccount:${google_service_account.slurm_login.email}",var.slurm_gcp_users, var.slurm_gcp_admins])
  }

  binding {
    role = "roles/compute.osLogin"
    members = var.slurm_gcp_users
  }

  binding {
    role = "roles/iam.serviceAccountUser"
    members = flatten([var.slurm_gcp_users,var.slurm_gcp_admins])
  }

  binding {
    role = "roles/compute.osAdminLogin"
    members = var.slurm_gcp_admins
  }

}


// ***************************************** //
// Create the cluster-config

locals {
  cluster_config = { compute_image = var.compute_image,
                     compute_service_accounts = google_service_account.slurm_compute.email,
                     controller_image = var.controller_image,
                     default_partition = var.default_partition,
                     login_image = var.login_image,
                     partitions = var.partitions,
                     slurm_accounts = var.slurm_accounts,
                     name = var.name,
                     tags = var.tags,
                     controller = var.controller,
                     login = var.login,
                     mounts = var.mounts,
                     slurm_db = var.slurm_db,
                     munge_key = var.munge_key,
                     suspend_time = var.suspend_time
                   }
}

// ***************************************** //
// Create the controller

resource "google_compute_instance" "controller_node" {
  name = "${var.name}-controller"
  project = var.controller.project
  machine_type = var.controller.machine_type
  zone = var.controller.zone
  tags = var.tags
  boot_disk {
    auto_delete = true
    initialize_params {
      image = var.controller_image
      size = var.controller.disk_size_gb
      type = var.controller.disk_type
    }
  }
  labels = var.controller.labels 
  metadata_startup_script = file("${path.module}/scripts/controller-startup-script.sh")
  metadata = {
    cluster-config = jsonencode(local.cluster_config)
    compute-service-account = google_service_account.slurm_compute.email
    enable-oslogin = "TRUE"
  }
  network_interface {
    subnetwork  = var.controller.vpc_subnet
    access_config {
     // Currently create instance with ephemeral IP
     // Specifying external IP causes failure
     //   Error: Error creating instance: googleapi: Error 400: 
     //   Invalid value for field 'resource.networkInterfaces[0].accessConfigs[0].natIP': '34.102.243.0'. 
     //   The specified external IP address '34.102.243.0' was not found in region 'us-east1'., invalid
     //   on ../modules/slurm-gcp-zfs/main.tf line 79, in resource "google_compute_instance" "controller_node":
     //   79: resource "google_compute_instance" "controller_node" {
     //
     //nat_ip = google_compute_global_address.controller.address
    }
  }
  service_account {
    email  = google_service_account.slurm_controller.email
    scopes = ["sql-admin","storage-ro","logging-write","monitoring-write","compute-rw"]
  }
  lifecycle{
    ignore_changes = [metadata_startup_script]
  }
  allow_stopping_for_update = true
  depends_on = [google_service_account.slurm_controller]
}

// ***************************************** //
// Create the login nodes

resource "google_compute_instance" "login_node" {
  count = length(var.login)
  name = "${var.name}-login-${count.index}"
  project = var.login[count.index].project
  machine_type = var.login[count.index].machine_type
  zone = var.login[count.index].zone
  tags = var.tags
  boot_disk {
    auto_delete = true
    initialize_params {
      image = var.login_image
      size = var.login[count.index].disk_size_gb
      type = var.login[count.index].disk_type
    }
  }
  labels = var.login[count.index].labels 
  metadata_startup_script = file("${path.module}/scripts/login-startup-script.sh")
  metadata = {
    cluster-config = jsonencode(local.cluster_config)
    cluster_name = var.name
    enable-oslogin = "TRUE"
  }
  network_interface {
    subnetwork  = var.login[count.index].vpc_subnet
    access_config {
     // Currently create instance with ephemeral IP
     // Specifying external IP causes failure
     //   Error: Error creating instance: googleapi: Error 400: 
     //   Invalid value for field 'resource.networkInterfaces[0].accessConfigs[0].natIP': '34.102.243.0'. 
     //   The specified external IP address '34.102.243.0' was not found in region 'us-east1'., invalid
     //   on ../modules/slurm-gcp-zfs/main.tf line 79, in resource "google_compute_instance" "login_node":
     //   79: resource "google_compute_instance" "login_node" {
     //
     //nat_ip = google_compute_global_address.login[count.index].address
    }
  }
  service_account {
    email  = google_service_account.slurm_login.email
    scopes = ["storage-full","logging-write","monitoring-write"]
  }
  lifecycle{
    ignore_changes = [metadata_startup_script]
  }
  depends_on = [google_compute_instance.controller_node,
                google_service_account.slurm_login]
}
