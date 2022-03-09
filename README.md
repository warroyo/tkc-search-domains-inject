# TKGs Search Domains Injector

This can be used to add search domains to guest clusters automatically. This will run as a pod in the supervisor cluster and continuously ssh out to the guest cluster nodes and make sure they have the correct search domains configured.When using this with VDS networking the pod will run on the control plane nodes. This will run on a per namespace basis. This also leverages the `docker-registry` running in the supervisor cluster to store the `domains-inject` docker image to reduce external dependencies on internal registries existing.

**NOTE: when upgrading the Supervisor Cluster it will role the nodes so the image for domains-inject that is stored on the local registry will be removed. you will need to re-run the install script to re-upload the image otherwise you will get image pull errors**


## Compatibility

Right now this has only been tested against TKGs installs using VDS networking.


## Usage

1. ssh to vcenter and hop into shell
2. **be sure to do a DCLI login otherwise the script will hang waiting for a password** run the command below and it should prompt you. When asked to store creds say yes.

```
dcli +server <server> +skip-server-verification com vmware vcenter cluster list
```

3. copy this repo over to your vcenter , you can download the zip from github and scp or curl it down to vcenter if you have internet access. you will then want to unzip the file on vcenter and `cd` into the directory that it created.
4. next grab the `domains-inject.tar.gz` from the github releases and upload it to your vcenter VM. you can do this scp or if you have internet connection out from vcenter just pull it down to the vm. copy the `tar.gz` it into the newly created repo directory, no need unzip it.
5. open `env.sh` and fill in the variables
6. execute `install.sh`

## Upgrading

1. ssh to vcenter and hop into shell
2. copy your `env.sh` out of the root repo folder
3. pull down the latest release of the code base to replace the existing one
4. pull down the latest release of `domains-inject.tar.gz` to replace the existing one
5. copy your `env.sh` back into the root of the repo replacing the default one
6. update any new env vars
7. execute `install.sh`

## Vars

all vars are set in `env.sh`

* `VSPHERE_CLUSTER` -  the vsphere cluster name that wcp is enabled on
* `DEPLOY_NS` - namespace that the proxy pod will be deployed into
* `DOMAINS` - the search domains you want to add separated by a space. 
* `INTERVAL` - interval to run the script


**NOTE: NOT TESTED FOR PRODUCTION USE**