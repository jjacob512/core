# Dev System Configuration

Engineers value documentation that explains how to get a development workstation configured quickly. It is human nature to customize and change things - we do this frequently, but sometimes we need to get back to first base.  This document will help to get you there.

##Installation and Configuration Information

> An attempt has been made to pre-stage downloads so several steps can be done in parallel.  The docker image pull also has a large download it's OK to read ahead and start that too.

###Base OS Installed
  1. VirtualBox, THREE network interfaces
    1. (assumed to be eth0) bridge external 
    1. (assumed to be eth1) on a host-only network 192.168.124.0/24.  Give it a reasonable unused IP. 192.168.124.7 is good.
    1. (assumed to be eth2) on a host-only network 192.168.124.0/24.  *NO IP assignment* or OS interface configuration (`/etc/network/interfaces` or `/etc/sysconfig`). If using Docker, setup bridging as in [docker/docker-admin.md](docker/docker-admin.md)
  1. Setup an .ssh keypair using `ssh-keygen`
  1. Optional Items that we find handy if you are developing on Windows using VMs behind corporate firewalls
    1. Squid Proxy (to cache packages)
      1. ubuntu: `sudo apt-get install squid squid-common`
    1. CNTLM proxy: 
      1. ubuntu: `sudo apt-get install cntlm`
      1. make sure that you allow NON local hosts to use the proxy (in `/etc/cntlm.conf` set `gateway yes`)!  Containers are not "local" and require your CNTLM proxy to act as a gateway.
    1. SAMBA share
      1. ubuntu: `sudo apt-get install samba`
    1. Passwordless sudo: `sudo sed -ie "s/%sudo\tALL=(ALL:ALL) ALL/%sudo ALL=(ALL) NOPASSWD: ALL/g" /etc/sudoers`
  1. if you are stuck behind a proxy, make sure your environment does not use it for local addresses: `export no_proxy="127.0.0.1,[::1],localhost,192.168.124.0/24,172.16.0.0/12"`
  1. `apt-get install git`

###Position Boot Assets
  
> We'll need this for later but it takes a while so we do it now....

Copy the ISOs that you want for nodes to `$HOME/.cache/opencrowbar/tftpboot/isos`.  It's OK to have more than 1 but make sure you have the space!

Examples:
  1. `mkdir -p $HOME/.cache/opencrowbar/tftpboot/isos`
  1. `cd $HOME/.cache/opencrowbar/tftpboot/isos`
  1. Centos: `wget http://centos.mirror.ndchost.com/6.5/isos/x86_64/CentOS-6.5-x86_64-bin-DVD1.iso`
  1. Ubuntu: `wget http://releases.ubuntu.com/12.04.4/ubuntu-12.04.4-server-amd64.iso`

###Checkout Code 
  1. get git
    1. ubuntu: `sudo apt-get install git`
  1. get the code: `git clone https://github.com/opencrowbar/core`

If you want to **commit code or docs fixes**, please review [the Contributor guide](../contributing.md)

###Build Sledgehammer (do 1 time, but takes a while)
  1. prep for sledgehammer requirements: 
    1. ubuntu: `sudo apt-get install rpm rpm2cpio`
  1. from core, `tools/build_sledgehammer.sh`
    1. warning: this may take multiple attempts to complete to downloads.  Keep trying.
    2. warning: might need a better literal mirror in sledgehammer/sledgehammer.ks - see [Details]((../../workflow/dev-build-sledgehammer.md))

###Setup Docker Admin Node 
  1. follow steps in [docker/docker-admin.md](docker/docker-admin.md)

