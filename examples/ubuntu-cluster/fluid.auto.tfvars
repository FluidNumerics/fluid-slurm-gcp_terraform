cluster_name = "demo"
primary_project = "TO DO"
primary_zone = "TO DO "
slurm_gcp_admins = ["group:TO DO"]
slurm_gcp_users = ["user:TO DO"]
slurm_accounts = [{ name = "TO DO",
                    users = ["TO DO"]
                    allowed_partitions = ["demo"]
                 }]


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
                             zone = "TO DO"
                          }]
               }
]




 
