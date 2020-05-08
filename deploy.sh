#!/bin/bash

export THT=/home/stack/templates
export LOG=logs/deploy_$(date +%F_%s).log
export OUTPUT=logs/output_$(date +%F_%s).log

[ -w deploy_nr.txt ] && echo $(( $(cat deploy_nr.txt) + 1 )) > deploy_nr.txt || echo 1 > deploy_nr.txt 


echodo () {

   echo "======================================================== " >> deploy_attempts.log
   echo "Deploy attempt #$(cat deploy_nr.txt) $( date '+%F %T' ) " >> deploy_attempts.log
   echo "======================================================== " >> deploy_attempts.log
   echo "$*" >> deploy_attempts.log
   eval $*
   echo "======================================================== " >> deploy_attempts.log
}

touch $LOG
rm last.log
ln -s $LOG last.log

echodo time openstack overcloud deploy \
--timeout 1200 \
--config-download-timeout 1200 \
--verbose \
--libvirt-type kvm \
--ntp-server 192.168.3.254 \
--validation-errors-nonfatal \
--disable-validations \
--templates \
-r ${THT}/roles_data.yaml \
-n ${THT}/network_data.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/network-environment.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/ceph-ansible/ceph-ansible.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/ceph-ansible/ceph-mds.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/ceph-ansible/ceph-rgw.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/cinder-backup.yaml \
-e ${THT}/network-environment.yaml \
-e ${THT}/common.yaml \
-e ${THT}/node-info.yaml \
-e ${THT}/local-registry.yaml \
-e ${THT}/dnsmasq-dns.yaml \
-e ${THT}/ceph-config.yaml \
-e ${THT}/predictable-ips.yaml \
-e ${THT}/hostnames.yaml \
--log-file $LOG | tee -a $OUTPUT

# -e ${THT}/rhsm.yaml \
# -e ${THT}/ceph-config.yaml \
# -e /usr/share/openstack-tripleo-heat-templates/environments/net-bond-with-vlans.yaml \
