
cluster_name = "CLUSTER NAME"
primary_project = "PROJECT ID"
primary_zone = "ZONE"
email_address = "EMAIL_ADDRESS"

controller_machine_type = "n1-standard-16"
controller_disk_size_gb = 1024 
login_machine_type = "n1-standard-2"

partitions = [{name = "wrf-demo"
               project = ""
               max_time = "8:00:00"
               labels = {"slurm-gcp"="compute"}
               machines = [{ name = "c2-60"
                             disk_size_gb = 150
                             gpu_count = 0
                             gpu_type = ""
                             image = "projects/wrf-gcp/global/images/wrf-gcp"
                             machine_type = "c2-standard-60"
                             max_node_count = 20
                             preemptible_bursting = false
                             zone = ""
                          }]
               }
]



 
// Settings for CloudSQL as Slurm database
//cloudsql_slurmdb = false
//cloudsql_name = "slurmdb"
//cloudsql_tier = "db-n1-standard-8"
