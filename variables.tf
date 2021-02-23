variable "slurm_gcp_admins" {
  type = list(string)
  description = "List of users or groups to provide slurm-gcp admin role"
}

variable "parent_folder" {
  type = string
  default = ""
  description = "A GCP folder id (folders/FOLDER-ID) that contains the Fluid-Slurm-GCP controller project and compute partition projects."
}

variable "slurm_gcp_users" {
  type = list(string)
  description = "List of users or groups to provide slurm-gcp user role"
}

variable "name" {
  type = string
  description = "Name of the cluster"
}

variable "tags" { 
  type = list(string)
  default = []
  description = "GCP network tags to apply to all instances in the cluster."
}

variable "controller_image" {
  type = string
  description = "Image to use for the fluid-slurm-gcp controller"
  default = "projects/fluid-cluster-ops/global/images/fluid-slurm-gcp-controller-centos"
}

variable "compute_image" {
  type = string
  description = "Image to use for the fluid-slurm-gcp compute instances (all partitions[].machines[])."
  default = "projects/fluid-cluster-ops/global/images/fluid-slurm-gcp-compute-centos"
}

variable "login_image" {
  type = string
  description = "Image to use for the fluid-slurm-gcp login node"
  default = "projects/fluid-cluster-ops/global/images/fluid-slurm-gcp-login-centos"
}

variable "controller" { 
  type = object({
      machine_type = string
      disk_size_gb = number
      disk_type = string
      labels = map(string)
      project = string
      region = string
      vpc_subnet = string
      zone = string
  })
  description = "Settings for the controller instance."
}

variable "default_partition" {
  type = string
  description = "Name of the default compute partition."
  default = "default"
}

variable "login" {
  type = list(object({
      machine_type = string
      disk_size_gb = number
      disk_type = string
      labels = map(string)
      project = string
      region = string
      vpc_subnet = string
      zone = string
  }))
  description = "Settings for the login instances."
}

variable "mounts" {
  type = list(object({
      group = string
      mount_directory = string
      mount_options = string
      owner = string
      protocol = string
      permission = string
      server_directory = string
  }))
  default = []
  description = "Settings for external mounts to attach to instances in this cluster."
}

variable "partitions" {
  type = list(object({
      name = string
      project = string
      max_time= string
      labels = map(string)
      machines = list(object({
        name = string
        disk_size_gb = number
        disk_type = string
        disable_hyperthreading= bool
        external_ip = bool
        gpu_count = number
        gpu_type = string
        image = string
        n_local_ssds = number
        local_ssd_mount_directory = string
        machine_type=string
        max_node_count= number
        preemptible_bursting= bool
        static_node_count= number
        vpc_subnet = string
        zone= string    
      }))
  }))
  description = "Settings for partitions and compute instances available to the cluster."
}

variable "slurm_db" {
  type = object({
    cloudsql_name = string
    cloudsql_ip = string
    cloudsql_port = number
  })
  default = { cloudsql_name = "", 
              cloudsql_ip = "", 
              cloudsql_port = 0}
}
  
variable "slurm_accounts" {
  type = list(object({
      name = string
      users = list(string)
      allowed_partitions = list(string)
  }))
  default = []
  description = "Settings for Slurm accounting."
}

variable "munge_key" {
  type = string
  default = ""
  description = "Munge authentication key to use for authenticating Slurm communications."
}

variable "suspend_time" {
  type = number
  default = 300
  description = "The amount of time, in seconds, to wait before suspending ephemeral compute instances."
}
