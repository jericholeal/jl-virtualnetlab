# jl-virtualnetlab
A fully virtual network lab simulating an enterprise LAN with routing, firewalls, monitoring, and automated backups.

Run on my personal host computer, I tried to keep the resource requirements


## Architecture
- **Virtualization** QEMU/KVM (Pop_OS! Linux host)
- **Bridge Interface**: br0 for internal LAN
- **Firewall**: nftables (default drop, allow-by-policy)
- **DHCP/DNS**: dnsmasq (router01 VM)
- **Automated Backups**: anacron, daily file backups
- **Prometheus & Grafana Monitoring**: node_exporter (Linux), windows_exporter (Windows)

## VM Inventory

### admin01
- Central Workstation
- Debian 12, XFCE
- 2 vCPU, 2GB RAM, 10GB disk (qcow2)

### router01
- Gateway, DHCP/DNS
- Debian 12 (no GUI)
- 1 vCPU, 512MB RAM, 4GB disk

### fileserver01
- NFS/SMB Host, File Sharing
- Ubuntu Server Minimized
- 1 vCPU, 1GB RAM, 10GB disk

### monitor01
- Monitoring, Prometheus & Grafana
- Ubuntu Server Minimized
- 2 vCPU, 2GB RAM, 15GB disk

### linuxclient01
- Linux Client VM
- AlmaLinux 10 Minimal (no GUI)
- 2 vCPU, 1536MB RAM, 8GB disk

### windowsclient01
- Windows Client VM
- Windows 10
- 2 vCPU, 4GB RAM, 80GB disk

### General Rules (nftables)
- All input/forward chains use default drop
- SSH to all VMs from admin01
- Traffic allowed as needed by role

### Networking
- Subnet: 192.168.100.0/24
- Gateway: 192.168.100.1 (router01)
- DHCP Range: 192.168.100.10 - 192.168.100.100 (12h)
- DHCP Leases (static): linuxclient01 (.101), windowsclient01 (.102)

### File Sharing
- NFS (fileserver01), /srv/nfsshare, mounted on linuxclient01 at /mnt/nfsshare
- Samba (fileserver01), /srv/smbshare, mapped network drive at :Z on windowsclient01

### Backups
- Backup scripts with anacron on fileserver01
- Compressed .tar.gz format
- Timestamped archives and logging

### Monitoring
- Prometheus & Grafana containerized with Docker
- Prometheus exposed on host port 9091, Grafana on 3000
- node_exporter installed on Linux VMs (port 9100), windows_exporter installed on windowsclient01 (port 9182)

### Future Improvements, Taking It Further
- Expand Grafana dashboards with alerts, retention tuning
- VPN access, remote management
- Software-based printer for network printer simulation
- Ansible playbooks for setup
- Dedicated backup server or cloud backups (e.g. Amazon S3)
- LDAP server

### Why did I do this project, anyway?

I wanted to build something to learn, practice, and apply networking and system administration skills and knowledge.

### Key Areas of Learning & Experience:
- Subnetting
- dnsmasq.conf, DHCP, leases
- nftables.conf, rule setting
- Prometheus & Grafana, node_exporter/windows_exporter
- Key ports
- SSH hardening
- Samba for Windows file sharing

### Some Problems I Ran Into:

#### Setting up host bridge
- Had problems with VMs staying connected to host bridge device
- Assigned static IP address to bridge device (192.168.100.254/24), and gateways & DNS as 192.168.100.1

#### No internet connectivity from linuxclient01
- DHCP worked, ping router01 worked, ping google.com didn't work
- router01 didn't have ipv4 forwarding permanently enabled
- sysctl and sysctl.conf to permanently allow ipv4 port forwarding

#### Initially planned on using iptables
- Learned about nftables and switched to that

#### Docker compose containers forever restarting
- Changed Grafana host directory ownership to 472:472
- Changed Prometheus host directory ownership to 65534:65534

#### Installed Ubuntu Server Minimized (monitor01) with the docker snap
- Working with the snap was weird, so I uninstalled it and went with docker.io

#### I actually created admin01 later
- I was using router01 as my central workstation
- While setting up Grafana, needed a GUI
- Set up admin01 and set it up as central workstation instead

#### Prometheus as data source for Grafana
- Initially tried connecting Grafana to Prometheus as a data source at monitor01's IP address at port 9091
- Learned that since Grafana & Prometheus are in the same container stack, need to simply add the prometheus path instead

#### Trouble accessing smbshare on fileserver01 from windowsclient01
- ping was OK, but \\fileserver01\smbshare wasn't accessible
- I had the wrong sharename in smb.conf, so I fixed the name

#### linuxclient01 backups
- I added a static DHCP lease to linuxclient01 to simplify ssh backups from fileserver01