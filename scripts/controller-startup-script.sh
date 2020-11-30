#!/usr/bin/env bash

export PRINT_LOGS="False"
export SPINUP_TEST="False"

systemctl enable nfs-server
systemctl start nfs-server

/apps/cls/bin/cluster-services setup
/apps/cls/bin/cluster-services system-checks
