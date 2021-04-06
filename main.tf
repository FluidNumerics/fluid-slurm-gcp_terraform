// Configure the Google Cloud provider
provider "google" {
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

locals {
  iam_folder_count = (var.parent_folder == "") ? 0 : 1
  compute_admins = flatten(["serviceAccount:${google_service_account.slurm_controller.email}",var.slurm_gcp_admins])
  cloudsql_admins = flatten(["serviceAccount:${google_service_account.slurm_controller.email}",var.slurm_gcp_admins])
  storage_admins = flatten(["serviceAccount:${google_service_account.slurm_compute.email}","serviceAccount:${google_service_account.slurm_login.email}",var.slurm_gcp_admins])
  oslogin = var.slurm_gcp_users
  oslogin_admins = var.slurm_gcp_admins
  service_account_users = flatten([var.slurm_gcp_users,var.slurm_gcp_admins,"serviceAccount:${google_service_account.slurm_controller.email}"])
  primary_region = trimsuffix(var.controller.zone,substr(var.controller.zone,-2,-2))
}


// Opt for non-authorizative modifications to project IAM policies
resource "google_project_iam_member" "project_compute_admins" {
  count = length(local.compute_admins)
  project = var.controller.project
  role = "roles/compute.admin"
  member = local.compute_admins[count.index]
}

resource "google_project_iam_member" "project_cloudsql_admins" {
  count = length(local.cloudsql_admins)
  project = var.controller.project
  role = "roles/cloudsql.admin"
  member = local.cloudsql_admins[count.index]
}

resource "google_project_iam_member" "project_storage_admins" {
  count = length(local.storage_admins)
  project = var.controller.project
  role = "roles/storage.admin"
  member = local.storage_admins[count.index]
}

resource "google_project_iam_member" "project_oslogin" {
  count = length(local.oslogin)
  project = var.controller.project
  role = "roles/compute.osLogin"
  member = local.oslogin[count.index]
}

resource "google_project_iam_member" "project_oslogin_admin" {
  count = length(local.oslogin_admins)
  project = var.controller.project
  role    = "roles/compute.osAdminLogin"
  member = local.oslogin_admins[count.index]
}

resource "google_project_iam_member" "project_service_account_users" {
  count = length(local.service_account_users)
  project = var.controller.project
  role = "roles/iam.serviceAccountUser"
  member = local.service_account_users[count.index]
}

// If a folder is provided, set the IAM policies on the parent folder that houses the slurm-gcp deployment
resource "google_folder_iam_policy" "slurm_gcp_folder_policy" {
  count = local.iam_folder_count
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
    members = flatten(["serviceAccount:${google_service_account.slurm_compute.email}","serviceAccount:${google_service_account.slurm_login.email}",var.slurm_gcp_admins])
  }

  binding {
    role = "roles/compute.osLogin"
    members = var.slurm_gcp_users
  }

  binding {
    role = "roles/iam.serviceAccountUser"
    members = flatten([var.slurm_gcp_users,var.slurm_gcp_admins,"serviceAccount:${google_service_account.slurm_controller.email}"])
  }

  binding {
    role = "roles/compute.osAdminLogin"
    members = var.slurm_gcp_admins
  }

}


// ***************************************** //
// Create the Cloud SQL instance

resource "google_compute_global_address" "private_ip_address" {
  count = var.cloudsql_slurmdb ? 1 : 0
  provider = google-beta
  name = "private-ip-address"
  purpose = "VPC_PEERING"
  address_type = "INTERNAL"
  prefix_length = 16
  network = var.cloudsql_network
  project = var.controller.project
}

resource "google_service_networking_connection" "private_vpc_connection" {
  count = var.cloudsql_slurmdb ? 1 : 0
  provider = google-beta
  network = var.cloudsql_network
  service = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address[0].name]
}

resource "google_sql_database_instance" "slurm_db" {
  count = var.cloudsql_slurmdb ? 1 : 0
  provider = google-beta
  name = var.cloudsql_name
  database_version = "MYSQL_5_6"
  region = local.primary_region
  project = var.controller.project
  depends_on = [google_service_networking_connection.private_vpc_connection[0]]

  settings {
    tier = var.cloudsql_tier
    ip_configuration {
      ipv4_enabled  = var.cloudsql_enable_ipv4
      private_network = var.cloudsql_network
    }
  }
  deletion_protection = false
}

locals {
  slurm_db = var.cloudsql_slurmdb ? {"cloudsql_name":google_sql_database_instance.slurm_db[0].name, 
                                     "cloudsql_ip":google_sql_database_instance.slurm_db[0].private_ip_address,
                                     "cloudsql_port":6819} : {"cloudsql_name":"", 
                                                              "cloudsql_ip":"",
                                                              "cloudsql_port":6819}
}
// ***************************************** //
// Create the cluster-config

locals {
  cluster_config = { compute_image = var.compute_image,
                     compute_service_account = google_service_account.slurm_compute.email,
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
                     munge_key = var.munge_key,
                     suspend_time = var.suspend_time,
                     slurm_db = local.slurm_db
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
    }
  }
  service_account {
    email  = google_service_account.slurm_controller.email
    scopes = ["cloud-platform"]
  }
  lifecycle{
    ignore_changes = [metadata_startup_script]
  }
  allow_stopping_for_update = true
  depends_on = [google_service_account.slurm_controller,
                google_sql_database_instance.slurm_db]
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
    }
  }
  service_account {
    email  = google_service_account.slurm_login.email
    scopes = ["cloud-platform"]
  }
  lifecycle{
    ignore_changes = [metadata_startup_script]
  }
  allow_stopping_for_update = true
  depends_on = [google_compute_instance.controller_node,
                google_service_account.slurm_login]
}
