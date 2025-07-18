# jl-virtualnetlab
This repository contains only the configuration files and scripts for my "Virtual Net Lab" setup. It’s intended as a reference showcase, not a full deployable system.

You won’t find full installations, image files, or full project scaffolding here, just the essential configs and automation scripts I’ve written and used in my own setup.

### Why this lab?

I built this to practice networking and system administration in a hands-on way.

### Why this repo?
I created this repo to document and showcase key parts for learning & sharing.

### What's included?
- Bash scripts (backups)
- Sample config files (nftables, dnsmasq, sshd_config, etc.)
- Setup notes and learning documentation

## Architecture
- **Virtualization** QEMU/KVM (Pop_OS! Linux host)
- **Bridge Interface**: br0 for internal LAN
- **Firewall**: nftables (default drop, allow-by-policy)
- **DHCP/DNS**: dnsmasq (on router01)
- **Automated Backups**: anacron, daily .tar.gz archives
- **Monitoring**: Prometheus & Grafana (Docker), node_exporter, windows_exporter

## VM Inventory

Runs on my personal host. Kept resource usage minimal.

### admin01
- Central Workstation
- Debian 12, XFCE
- 2 vCPU, 2GB RAM, 10GB disk

### router01
- Gateway, DHCP/DNS
- Debian 12 (no GUI)
- 1 vCPU, 512MB RAM, 4GB disk

### fileserver01
- NFS/SMB Host, File Sharing
- Ubuntu Server (Minimized)
- 1 vCPU, 1GB RAM, 10GB disk

### monitor01
- Prometheus & Grafana stack
- Ubuntu Server (Minimized)
- 2 vCPU, 2GB RAM, 15GB disk

### linuxclient01
- AlmaLinux 10 Minimal (no GUI)
- 2 vCPU, 1536MB RAM, 8GB disk

### windowsclient01
- Windows 10
- 2 vCPU, 4GB RAM, 80GB disk

### Networking & Firewall
- Subnet: 192.168.100.0/24
- Gateway: 192.168.100.1 (router01)
- DHCP Range: 192.168.100.10 - 100 (12h lease)
- Static Leases: linuxclient01 (.101), windowsclient01 (.102)
- Firewall: default drop all, allow by role (e.g. SSH from admin01)

### File Sharing
- NFS (fileserver01): /srv/nfsshare, mounted at /mnt/nfsshare on linuxclient01
- Samba (fileserver01): /srv/smbshare, mapped as :Z on windowsclient01

### Backups
- Scripts on fileserver01 scheduled with anacron
- .tar.gz archives, timestamped
- Stored locally, logs written to /var/log/backups

### Monitoring
- Prometheus & Grafana containerized on monitor01
- Ports: Prometheus 9091, Grafana 3000
- node_exporter on Linux VMs (9100)
- windows_exporter on Windows (9182)

### Future Improvements
- Grafana alerts, dashboard tuning
- VPN access, remote lab control
- Simulated network printer
- Ansible playbooks for automation
- Dedicated backup VM or cloud backups (e.g. S3)
- Central LDAP authentication

### Key Learning Areas:
- Subnetting & DHCP leases with dnsmasq
- nftables rulesets
- Secure SSH config
- Using Prometheus & Grafana
- Using Docker
- Filesharing with NFS and Samba
- Bash scripting for backup automation
- Troubleshooting networking

### Problems & Learning Experiences:

#### Host bridge issues
- VMs not connecting properly
- Fixed by assigning 192.168.100.254/24 to bridge device and 192.168.100.1 as gateway & DNS

#### No internet on linuxclient01
- DHCP workd, router01 pinged, but no external access
- Port forwarding wasn't permanently enabled on router01 (missing net.ipv4.ip_forward = 1 in sysctl.conf)

#### Switched from iptables to nftables
- Learned nftables is the modern replacement, switched to it
- Cleaner and better design

#### Docker snap was weird
- Initial install of Docker via snap on monitor01 had issues
- Replaced with docker.io from apt

#### I actually created admin01 later
- Originally using router01 as my central workstation
- Set up admin01 as central GUI workstation instead

#### Docker containers stuck restarting
- Fixed by setting correct volume directory permissions
- Grafana: 472:472
- Prometheus: 65534:65534

#### Prometheus not reachable from Grafana
- Initially tried connecting Grafana to Prometheus as a data source at monitor01's IP address at port 9091
- Realized Grafana & Prometheus run in the same Docker network, used internal path instead of host IP and port

#### Trouble accessing smbshare on fileserver01 from windowsclient01
- fileserver01 pinged, but \\fileserver01\smbshare mounting failed
- Found sharename typo in smb.conf, fixed it

#### linuxclient01 backups problems
- Added a static DHCP lease to linuxclient01 to ensure consistent IP for SSH-based backups