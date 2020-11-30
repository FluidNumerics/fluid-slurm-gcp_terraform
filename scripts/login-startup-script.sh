#!/usr/bin/env bash

GOOGLE_URL="http://metadata.google.internal/computeMetadata/v1/instance/attributes"
CLUSTER_NAME=$(curl -H "Metadata-Flavor: Google" "${GOOGLE_URL}/cluster_name")
export PRINT_LOGS="False"
export SPINUP_TEST="False"

# Make sure other instances mount the /apps directory prior to executing any cluster services
mkdir -p /apps
echo "${CLUSTER_NAME}-controller:/apps	/apps	nfs	rw,hard,intr	0	0" >> /etc/fstab
echo "${CLUSTER_NAME}-controller:/home	/home	nfs	rw,hard,intr	0	0" >> /etc/fstab
echo "${CLUSTER_NAME}-controller:/etc/munge    /etc/munge     nfs      rw,hard,intr  0     0" >> /etc/fstab
#echo "${CLUSTER_NAME}-controller:/opt    /opt     nfs      rw,hard,intr  0     0" >> /etc/fstab
echo "# ADDITIONAL MOUNTS #" >> /etc/fstab
mount -a

/apps/cls/bin/cluster-services setup
/apps/cls/bin/cluster-services system-checks
