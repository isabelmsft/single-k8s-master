# Set Up Host Machine as Single Kubernetes Master

When running a virtual SONiC DUT on a host machine, the host machine can be configured as the Kubernetes master. The host machine may be a VM or server. 

Prerequisite: Set up virtual SONiC KVM as described [here](https://github.com/Azure/sonic-mgmt/blob/master/ansible/doc/README.testbed.VsSetup.md)

## Steps to setup basic Kubernetes master and SONiC KVM as worker node

On the host machine: 
```
$ git clone https://github.com/isabelmsft/single-k8s-master
$ cd single-k8s-master/
$ sudo ./setup-single-master.sh
```
The script will prompt you for some basic information to generate SSL certs. You may just hit enter, using the default empty values. 

Afterwards, you can see that the host machine has been configured as the Kubernetes master:  
```
$ sudo kubectl get nodes
NAME              STATUS     ROLES    AGE    VERSION
str-acs-serv-21   Ready      master   50m    v1.19.3
```

To join the virtual SONiC DUT to the Kubernetes master, ssh into the virtual SONiC DUT and configure as follows:
```
$ ssh admin@10.250.0.101
```

From inside the virtual SONiC DUT: 
```
admin@vlab-01:~$ sudo config kube server disable off
admin@vlab-01:~$ sudo config kube server ip <IP address of main interface of host machine>
```
The configured IP address should match the server IP output in the file `$HOME/.kube/config` on the host machine. This file was generated as part of the Kubernetes cluster initialization by the `setup-single-master.sh` script. 

After about 45 seconds, you should observe that the SONiC DUT is connected to the Kubernetes master server: 
```
admin@vlab-01:~$ show kube server
Kubernetes server config:
KUBERNETES_MASTER SERVER ip 10.130.48.224
KUBERNETES_MASTER SERVER insecure True
KUBERNETES_MASTER SERVER disable False
KUBERNETES_MASTER SERVER port 6443

Kubernetes server state:
KUBERNETES_MASTER SERVER ip 10.130.48.224
KUBERNETES_MASTER SERVER update_time 2020-11-07 03:53:54
KUBERNETES_MASTER SERVER connected true
KUBERNETES_MASTER SERVER port 6443
```
You may also check `/var/log/syslog` to monitor join progress. 

From the host machine, you can see that the virtual switch has joined to the master: 
```
$ sudo kubectl get nodes
NAME              STATUS     ROLES    AGE    VERSION
str-acs-serv-21   Ready      master   50m    v1.19.3
vlab-01           NotReady   <none>   7m7s   v1.18.6
```

