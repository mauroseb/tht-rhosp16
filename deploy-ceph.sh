#!/bin/bash                                         

export THT=/home/stack/templates
export LOG=logs/deploy_$(date +%F_%s).log
export OUTPUT=logs/output_$(date +%F_%s).log
export NETBOT_SEND=./netbot-send.py

[ -w deploy_nr.txt ] && echo $(( $(cat deploy_nr.txt) + 1 )) > deploy_nr.txt || echo 1 > deploy_nr.txt 

echodo () {

   echo "======================================================== " >> deploy_attempts.log
   echo "Deploy attempt #$(cat deploy_nr.txt) $( date '+%F %T' ) " >> deploy_attempts.log
   echo "======================================================== " >> deploy_attempts.log
   echo "$*" >> deploy_attempts.log
   eval $*
   if [ $? -ne 0 ]; then
        echo "FAILURES:" >> deploy_attempts.log
        openstack stack failures list --long overcloud >> deploy_attempts.log
        echo "YOUR DEPLOYMENT FAILED AGAIN!" | ssh stack@192.168.122.1 espeak-ng -s 160
        
        [[ -x $NETBOT_SEND ]] && $NETBOT_SEND "Deploy $DEPLOY_NR failed!"
   else
        echo "SUCCESFUL!" >> deploy_attempts.log
        echo "YOU HAVE CHOSEN WISELY!" | ssh stack@192.168.122.1 espeak-ng -s 160
        [[ -x $NETBOT_SEND ]] && $NETBOT_SEND "Deploy $DEPLOY_NR succeeded!"
   fi
   echo "======================================================== " >> deploy_attempts.log
}

touch $LOG
rm last.log
ln -s $LOG last.log

echodo time openstack overcloud deploy \
--timeout 600 \
--config-download-timeout 600 \
--libvirt-type kvm \
--ntp-server 192.168.3.254 \
--validation-errors-nonfatal \
--disable-validations \
--verbose \
--templates \
-r ${THT}/roles_data.yaml \
-e ${THT}/node-info.yaml \
-e ${THT}/local-registry.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/network-environment.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/ceph-ansible/ceph-ansible.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/ceph-ansible/ceph-rgw.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/ceph-ansible/ceph-mds.yaml \
-e /usr/share/openstack-tripleo-heat-templates/environments/cinder-backup.yaml \
-e ${THT}/network-environment.yaml \
-n ${THT}/network_data.yaml \
-e ${THT}/ceph-config.yaml \
-e ${THT}/dnsmasq-dns.yaml \
-e ${THT}/predictable-ips.yaml \
-e ${THT}/common.yaml \
-e ${THT}/hostnames.yaml \
-e ${THT}/barbican.yaml \
-e ${THT}/rhsm.yaml \
-e ${THT}/extras.yaml \
-e ${THT}/security.yaml \
--log-file $LOG | tee -a $OUTPUT

# -e ${THT}/bz1743330.yaml \
# -e ${THT}/glance-nfs.yaml \
# -e ${THT}/custom-horizon.yaml \
