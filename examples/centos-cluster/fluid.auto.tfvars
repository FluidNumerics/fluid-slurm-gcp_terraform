cluster_name = "CLUSTER NAME"
primary_project = "PROJECT"
primary_zone = "ZONE"
slurm_gcp_admins = ["group:support@example.com"]
slurm_gcp_users = ["user:someone@example.com"]
slurm_accounts = [{ name = "demo-account",
                    users = ["someone"]
                    allowed_partitions = ["demo"]
                 }]


// compute_image = "projects/PROJECT ID/global/images/IMAGE NAME"
controller_machine_type = "n1-standard-8"
login_machine_type = "n1-standard-8"

partitions = [{name = "demo"
               project = ""
               max_time = "8:00:00"
               labels = {"slurm-gcp"="compute"}
               machines = [{ name = "demo"
                             disk_size_gb = 30
                             gpu_count = 0
                             gpu_type = ""
                             image = ""
                             machine_type = "c2-standard-60"
                             max_node_count = 100
                             preemptible_bursting = false
                             zone = "ZONE"
                          }]
               }
]




 
