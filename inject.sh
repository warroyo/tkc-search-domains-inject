#!/bin/bash

# Logging function that will redirect to stderr with timestamp:
logerr() { echo "$(date) ERROR: $@" 1>&2; }
# Logging function that will redirect to stdout with timestamp
loginfo() { echo "$(date) INFO: $@" ;}



run_interval=${INTERVAL:=30}


function inject_search_domains()
{

  echo "checking if search domains exists"
  mkdir -p /etc/systemd/network/10-gosc-eth0.network.d
  touch /etc/systemd/network/10-gosc-eth0.network.d/00-domains.conf
  if cmp -s "/etc/systemd/network/10-gosc-eth0.network.d/00-domains.conf.new" "/etc/systemd/network/10-gosc-eth0.network.d/00-domains.conf"; then
      echo "the search domains already exists and have not changed"
  else
      echo "updating the search domains"
      mv /etc/systemd/network/10-gosc-eth0.network.d/00-domains.conf.new /etc/systemd/network/10-gosc-eth0.network.d/00-domains.conf
      chmod -R 755 /etc/systemd/network/10-gosc-eth0.network.d
      systemctl restart systemd-networkd
      echo "domains updated!"
  fi

}


function run()
{

  #get the machines
  machines=$(kubectl get virtualmachines -o json)

  for row in $(echo "${machines}" | jq -r '.items[] | @base64'); do
      _jq() {
      echo ${row} | base64 -d | jq -r ${1}
      }
      loginfo "-------------------"
      #get the namespace 
      ns=$(_jq '.metadata.namespace')
      loginfo "namespace: ${ns}"

      #get the cluster name for the machine
      cluster=$(_jq '.metadata.labels."capw.vmware.com/cluster.name"')
      loginfo "cluster: ${cluster}"

      #get the ip for the machine
      ip=$(_jq '.status.vmIp')
      loginfo "ip: ${ip}"

      #get the secret for the machine and create a file
      loginfo "getting ssh key for ${cluster}"
      kubectl get secret ${cluster}-ssh -n ${ns} -o jsonpath="{.data.ssh-privatekey}" | base64 -d > /tmp/sshkey.pem
      chmod 600 /tmp/sshkey.pem

      #Check to make sure the cluster is healthy before trying to ssh and mess with settings
      currentStatus=$(kubectl get tkc $cluster -o=jsonpath='{.status.conditions[?(@.type=="NodesHealthy")].status}')
      statusDone="True"
      loginfo "Current Cluster Status: ${currentStatus}"
      if [ "Y$currentStatus" != "Y$statusDone"  ]; then 
        loginfo "cluster is not in a ready state, will retry"
        exit 0
      fi

      loginfo "attempting ssh to ${ip}"
      ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i /tmp/sshkey.pem vmware-system-user@${ip} << EOF
      sudo -i

      if [[ -z "${DOMAINS}" ]]
      then
        echo no Domains provided, skipping...
      else
       $(typeset -f inject_ca)
       echo -e "[Network]\nDomains=${DOMAINS}"  > /etc/systemd/network/10-gosc-eth0.network.d/00-domains.conf.new
       inject_ca
      fi


EOF

  if [ $? -eq 0 ] ;
  then  
        loginfo "script ran successfully!"
  else
        logerr "There was an error running the script Exiting..."
  fi


loginfo "-------------------"
  done
}

while true
do
    set +e
    echo "running script in a loop"
    run
    sleep $run_interval
done
