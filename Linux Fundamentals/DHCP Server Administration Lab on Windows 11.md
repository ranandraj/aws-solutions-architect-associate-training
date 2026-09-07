# DHCP Server Administration Lab on Windows 11
## Ubuntu Server, Oracle VirtualBox, WSL2, Vagrant and Ansible

---

# 1. Introduction

DHCP stands for:

```text
Dynamic Host Configuration Protocol
```

DHCP automatically provides network configuration to client computers.

Instead of manually configuring every computer with:

```text
IP address
Subnet mask
Default gateway
DNS server
```

a DHCP server can automatically provide these values.

For example:

```text
Client
   |
   | DHCP Request
   v
DHCP Server
   |
   | DHCP configuration
   v
Client receives:
IP       = 192.168.56.100
Mask     = 255.255.255.0
Gateway  = 192.168.56.1
DNS      = 192.168.56.10
```

Ubuntu describes DHCP as a service that automatically assigns network settings such as IP address, netmask, default gateway and DNS server to clients.

---

# 2. Lab Objectives

In this laboratory, two Ubuntu Server virtual machines will be created.

```text
DHCP Server
    |
    | DHCP
    |
    v
DHCP Client
```

The final environment will be:

| VM | Purpose | IP |
|---|---|---|
| dhcp01 | DHCP Server | 192.168.56.10 |
| client01 | DHCP Client | Automatically assigned |

DHCP network:

```text
192.168.56.0/24
```

DHCP pool:

```text
192.168.56.100 - 192.168.56.200
```

Gateway:

```text
192.168.56.1
```

DNS server supplied to clients:

```text
8.8.8.8
```

The DHCP server will provide the client with:

```text
IP address
Subnet mask
Default gateway
DNS server
Lease duration
```

---

# 3. Technologies Used

The lab contains the following layers:

```text
Windows 11
    |
    +-- Oracle VirtualBox
    |
    +-- WSL2 Ubuntu
            |
            +-- Vagrant
            |
            +-- Ansible
```

VirtualBox provides the virtual machines.

Vagrant automates VM creation.

WSL2 Ubuntu provides the Linux environment used for Ansible.

Ansible configures the Ubuntu VMs.

Kea provides DHCP service.

---

# 4. DHCP Architecture

The final architecture will look like:

```text
                         Windows 11
                             |
             +---------------+---------------+
             |                               |
        VirtualBox                         WSL2
             |                            Ubuntu
             |                               |
             |                         Vagrant + Ansible
             |
       Host-Only Network
        192.168.56.0/24
             |
       +-----+------+
       |            |
       v            v
    dhcp01       client01
192.168.56.10   DHCP client
       |
       |
      Kea
   DHCP Server
```

---

# 5. What is DHCP?

DHCP automatically supplies network configuration to hosts.

Without DHCP:

```text
Administrator
     |
     +-- Configure IP
     +-- Configure subnet mask
     +-- Configure gateway
     +-- Configure DNS
     |
     v
Each computer
```

With DHCP:

```text
Client
   |
   | DHCP
   v
DHCP Server
   |
   +-- IP address
   +-- Subnet mask
   +-- Gateway
   +-- DNS
   |
   v
Client
```

This makes network administration much easier.

---

# 6. DHCP Components

Important components are:

```text
DHCP Client
DHCP Server
DHCP Lease
DHCP Scope
DHCP Pool
DHCP Options
DHCP Relay
Reservation
```

---

# 7. DHCP Client

The DHCP client is the device requesting network configuration.

Examples:

```text
Laptop
Desktop
VM
Phone
Printer
Server
```

In this lab:

```text
client01
```

will act as the DHCP client.

---

# 8. DHCP Server

The DHCP server assigns network configuration.

In this lab:

```text
dhcp01
```

will be the DHCP server.

It will run:

```text
Kea DHCPv4
```

Ubuntu recommends Kea for new DHCP deployments.

---

# 9. DHCP Lease

A lease is the period for which a client is allowed to use an IP address.

For example:

```text
IP:
192.168.56.100

Lease:
1 hour
```

The client can use:

```text
192.168.56.100
```

for the lease period.

Before the lease expires, the client attempts to renew it.

---

# 10. DHCP Address Pool

A DHCP server normally maintains a pool of addresses.

Example:

```text
192.168.56.100 - 192.168.56.200
```

If three clients request addresses:

```text
client01 -> 192.168.56.100
client02 -> 192.168.56.101
client03 -> 192.168.56.102
```

---

# 11. DHCP Scope

A scope defines the network from which addresses are assigned.

Example:

```text
Network:
192.168.56.0/24

Pool:
192.168.56.100 - 192.168.56.200
```

The scope may also contain:

```text
Subnet mask
Gateway
DNS server
Lease time
Domain name
```

---

# 12. DHCP Options

DHCP can provide much more than an IP address.

Common options include:

| Option | Purpose |
|---|---|
| 1 | Subnet mask |
| 3 | Default gateway/router |
| 6 | DNS server |
| 12 | Hostname |
| 15 | Domain name |
| 51 | Lease time |
| 54 | DHCP server identifier |

For example:

```text
IP:
192.168.56.100

Subnet mask:
255.255.255.0

Gateway:
192.168.56.1

DNS:
8.8.8.8
```

---

# 13. DHCP DORA Process

The most important DHCP concept is:

```text
DORA
```

DORA stands for:

```text
D - Discover
O - Offer
R - Request
A - Acknowledgement
```

---

# 14. DHCP Discover

The client does not initially know the DHCP server's IP address.

It broadcasts:

```text
DHCPDISCOVER
```

Conceptually:

```text
client01
   |
   | DHCPDISCOVER
   | Broadcast
   v
Network
```

---

# 15. DHCP Offer

The DHCP server receives the request and offers an address.

Example:

```text
DHCPOFFER

IP:
192.168.56.100
```

Conceptually:

```text
dhcp01
   |
   | DHCPOFFER
   | 192.168.56.100
   v
client01
```

---

# 16. DHCP Request

The client requests the offered address.

```text
DHCPREQUEST
```

Example:

```text
I want:
192.168.56.100
```

---

# 17. DHCP Acknowledgement

The server confirms the allocation.

```text
DHCPACK
```

The client receives:

```text
IP:
192.168.56.100

Subnet:
255.255.255.0

Gateway:
192.168.56.1

DNS:
8.8.8.8
```

The complete process:

```text
Client                    DHCP Server
  |                            |
  |---- DHCPDISCOVER --------->|
  |                            |
  |<----- DHCPOFFER -----------|
  |                            |
  |---- DHCPREQUEST ---------->|
  |                            |
  |<------ DHCPACK ------------|
  |                            |
```

---

# 18. DHCP Ports

DHCP uses UDP.

Server:

```text
UDP 67
```

Client:

```text
UDP 68
```

Therefore:

```text
Client                         Server
UDP 68 ---------------------> UDP 67
UDP 68 <--------------------- UDP 67
```

---

# 19. DHCP Broadcast

DHCP is particularly important during initial network configuration because the client may not yet have an IP address.

Therefore, DHCP discovery commonly uses broadcast communication on the local network.

This is also why DHCP generally requires a DHCP server on the same Layer-2 broadcast domain unless a DHCP relay is used.

---

# 20. DHCP Reservation

A reservation associates a particular client with a specific IP address.

For example:

```text
MAC:
08:00:27:AA:BB:CC

Reserved IP:
192.168.56.50
```

Whenever that client requests DHCP, it receives:

```text
192.168.56.50
```

This is useful for:

```text
Printers
Servers
Network devices
Management systems
```

---

# 21. Dynamic Allocation

Dynamic allocation uses a pool.

Example:

```text
192.168.56.100 - 192.168.56.200
```

A client might receive:

```text
192.168.56.100
```

Another client:

```text
192.168.56.101
```

When the lease expires and the address is released, it can be reused.

Ubuntu documents dynamic allocation as assignment from a configured address pool for a lease period.

---

# 22. Automatic Allocation

Automatic allocation can permanently assign an address from a pool.

The main distinction from normal dynamic allocation is the lease duration.

---

# 23. DHCP Relay

Consider:

```text
Network A
192.168.10.0/24

        |
        |
     Router
        |
        |
Network B
192.168.20.0/24
```

The DHCP server may be located on another network.

A DHCP relay forwards DHCP requests between the client network and DHCP server.

Architecture:

```text
Client
   |
   v
DHCP Relay
   |
   v
DHCP Server
```

This is important in larger enterprise networks.

---

# 24. DHCP and DNS

DHCP and DNS perform different jobs.

DHCP:

```text
Provides network configuration
```

DNS:

```text
Resolves names to addresses
```

They are often used together.

Example:

```text
DHCP
 |
 +-- IP address
 +-- Gateway
 +-- DNS server
             |
             v
            DNS
             |
             +-- client01.example.com
                 -> IP address
```

Kea also includes a Dynamic DNS component that can update DNS based on DHCP lease events.

---

# 25. DHCP Server Software on Ubuntu

Ubuntu currently provides several DHCP server choices.

For new deployments, the recommended server is:

```text
Kea
```

Ubuntu documentation states that `isc-kea` is the recommended DHCP server for new deployments and is available from Ubuntu 23.04 onward.

Another option is:

```text
dnsmasq
```

which provides both DNS and DHCP.

The older:

```text
isc-dhcp-server
```

is deprecated and unsupported in Ubuntu 24.04 LTS.

Therefore, this laboratory uses:

```text
Kea DHCPv4
```

---

# PART A
# INSTALL WSL2 UBUNTU

---

# 26. Check Windows

Open PowerShell:

```powershell
winver
```

Confirm that Windows 11 is installed.

---

# 27. Install WSL

Open PowerShell as Administrator:

```powershell
wsl --install
```

Restart Windows if requested.

Check:

```powershell
wsl --status
```

Then:

```powershell
wsl -l -v
```

Expected:

```text
NAME      STATE      VERSION
Ubuntu    Running    2
```

The important value is:

```text
VERSION 2
```

---

# 28. Start Ubuntu

Open:

```text
Start
    -> Ubuntu
```

Create a Linux username and password when prompted.

For example:

```text
Username:
admin
```

---

# 29. Update Ubuntu

Inside WSL:

```bash
sudo apt update
```

Then:

```bash
sudo apt upgrade -y
```

Check:

```bash
cat /etc/os-release
```

---

# PART B
# INSTALL ORACLE VIRTUALBOX

---

# 30. Install VirtualBox

Install Oracle VirtualBox on Windows.

After installation:

```powershell
VBoxManage --version
```

Example:

```text
7.x.x
```

---

# 31. Verify Virtualization

Open:

```text
Task Manager
    -> Performance
    -> CPU
```

Check:

```text
Virtualization: Enabled
```

---

# PART C
# CREATE THE DHCP LAB NETWORK

---

# 32. Network Design

We will use:

```text
Network:
192.168.56.0/24
```

Host:

```text
192.168.56.1
```

DHCP Server:

```text
192.168.56.10
```

DHCP Client:

```text
DHCP assigned
```

DHCP pool:

```text
192.168.56.100 - 192.168.56.200
```

---

# 33. Important DHCP Design Rule

The DHCP server itself should normally use a static IP address.

Therefore:

```text
dhcp01
192.168.56.10
```

is manually configured.

The client will use DHCP.

```text
client01
DHCP
```

This creates a clear demonstration:

```text
Static DHCP Server
       |
       | DHCP
       v
Dynamic DHCP Client
```

---

# 34. Create VirtualBox Host-Only Network

Open VirtualBox.

Go to:

```text
File
 -> Tools
 -> Network Manager
```

Create a Host-only network.

Use:

```text
IPv4:
192.168.56.1

Mask:
255.255.255.0
```

For this lab, disable the VirtualBox DHCP server.

This is important because we want **our Ubuntu Kea server** to provide DHCP addresses, not VirtualBox's built-in DHCP service.

The network becomes:

```text
192.168.56.0/24

Windows Host
192.168.56.1

dhcp01
192.168.56.10

client01
DHCP
192.168.56.100+
```

---

# PART D
# MANUAL IMPLEMENTATION WITHOUT VAGRANT AND ANSIBLE

---

# 35. Create dhcp01 Manually

Open VirtualBox.

Select:

```text
New
```

Name:

```text
dhcp01
```

Type:

```text
Linux
```

Version:

```text
Ubuntu 64-bit
```

RAM:

```text
2048 MB
```

CPU:

```text
2
```

Disk:

```text
20 GB
```

---

# 36. Configure dhcp01 Networking

Use two adapters.

Adapter 1:

```text
NAT
```

Purpose:

```text
Internet
```

Adapter 2:

```text
Host-only Adapter
```

Network:

```text
192.168.56.0/24
```

---

# 37. Install Ubuntu Server

Install Ubuntu Server.

Hostname:

```text
dhcp01
```

Create:

```text
admin
```

Enable OpenSSH Server.

After installation:

```bash
hostname
```

Expected:

```text
dhcp01
```

---

# 38. Create client01

Create another VM:

```text
client01
```

RAM:

```text
2048 MB
```

CPU:

```text
2
```

Disk:

```text
20 GB
```

Network:

```text
Adapter 1 -> NAT
Adapter 2 -> Host-only
```

Install Ubuntu Server.

Hostname:

```text
client01
```

---

# 39. Configure Static IP on dhcp01

Check interfaces:

```bash
ip addr
```

Assume:

```text
enp0s3 = NAT
enp0s8 = Host-only
```

Do not assume the interface name. Always verify it.

Edit Netplan:

```bash
sudo nano /etc/netplan/50-cloud-init.yaml
```

Example:

```yaml
network:
  version: 2

  ethernets:

    enp0s3:
      dhcp4: true

    enp0s8:
      dhcp4: false
      addresses:
        - 192.168.56.10/24
```

Apply:

```bash
sudo netplan apply
```

Verify:

```bash
ip addr
```

Expected:

```text
192.168.56.10/24
```

---

# 40. Configure client01 for DHCP

On client01:

```bash
ip addr
```

Identify the Host-only interface.

Assume:

```text
enp0s8
```

Edit Netplan:

```bash
sudo nano /etc/netplan/50-cloud-init.yaml
```

Use:

```yaml
network:
  version: 2

  ethernets:

    enp0s3:
      dhcp4: true

    enp0s8:
      dhcp4: true
```

Apply:

```bash
sudo netplan apply
```

At this point, the Host-only interface will attempt to obtain its IP address using DHCP.

However, the DHCP server has not yet been installed.

Therefore, it may initially remain without a lease.

---

# 41. Test Connectivity

From dhcp01:

```bash
ping -c 4 192.168.56.1
```

From client01:

```bash
ping -c 4 192.168.56.10
```

The client may not yet have an address.

That is expected before installing Kea.

---

# PART E
# INSTALL KEA DHCP SERVER

---

# 42. Install Kea

On dhcp01:

```bash
sudo apt update
```

Install:

```bash
sudo apt install kea -y
```

Ubuntu's current Kea guide uses the `kea` package, which provides the DHCPv4 server along with other Kea components.

---

# 43. Kea Components

The installation provides components including:

```text
kea-dhcp4-server
kea-dhcp6-server
kea-ctrl-agent
kea-dhcp-ddns-server
```

For this laboratory we primarily use:

```text
kea-dhcp4-server
```

because the lab demonstrates IPv4 DHCP.

---

# 44. Important Kea Configuration File

The DHCPv4 configuration file is:

```text
/etc/kea/kea-dhcp4.conf
```

Kea's DHCPv4 server uses this file for DHCPv4 configuration.

---

# 45. Backup the Original Configuration

Run:

```bash
sudo cp /etc/kea/kea-dhcp4.conf \
/etc/kea/kea-dhcp4.conf.backup
```

---

# 46. Identify DHCP Interface

Run:

```bash
ip addr
```

Assume:

```text
enp0s8
```

is:

```text
192.168.56.10
```

This is the interface on which Kea will listen for DHCP requests.

---

# 47. Configure Kea DHCPv4

Edit:

```bash
sudo nano /etc/kea/kea-dhcp4.conf
```

Use:

```json
{
  "Dhcp4": {
    "interfaces-config": {
      "interfaces": [ "enp0s8" ]
    },

    "lease-database": {
      "type": "memfile",
      "persist": true,
      "name": "/var/lib/kea/dhcp4.leases"
    },

    "valid-lifetime": 3600,
    "renew-timer": 1800,
    "rebind-timer": 3150,

    "subnet4": [
      {
        "id": 1,
        "subnet": "192.168.56.0/24",

        "pools": [
          {
            "pool": "192.168.56.100 - 192.168.56.200"
          }
        ],

        "option-data": [
          {
            "name": "subnet-mask",
            "data": "255.255.255.0"
          },
          {
            "name": "routers",
            "data": "192.168.56.1"
          },
          {
            "name": "domain-name-servers",
            "data": "8.8.8.8"
          }
        ]
      }
    ]
  }
}
```

Kea's configuration model defines DHCPv4 subnets using `subnet4` and dynamic address pools using `pools`.

---

# 48. Understand the Configuration

## Interface

```json
"interfaces": [ "enp0s8" ]
```

Kea listens for DHCP traffic on:

```text
enp0s8
```

---

## Lease database

```json
"lease-database": {
    "type": "memfile",
    "persist": true,
    "name": "/var/lib/kea/dhcp4.leases"
}
```

Kea stores lease information.

Example:

```text
client MAC
     |
     v
192.168.56.100
     |
     v
lease information
```

---

## Lease lifetime

```json
"valid-lifetime": 3600
```

means:

```text
3600 seconds
=
1 hour
```

---

## DHCP subnet

```json
"subnet": "192.168.56.0/24"
```

defines the network.

---

## DHCP pool

```json
"pool": "192.168.56.100 - 192.168.56.200"
```

defines the addresses available for dynamic allocation.

---

# 49. Gateway Option

This:

```json
{
  "name": "routers",
  "data": "192.168.56.1"
}
```

tells the client:

```text
Default gateway =
192.168.56.1
```

---

# 50. DNS Option

This:

```json
{
  "name": "domain-name-servers",
  "data": "8.8.8.8"
}
```

tells the client:

```text
DNS Server =
8.8.8.8
```

Later, this can be changed to an internal DNS server such as:

```text
192.168.56.10
```

if the same system is also running DNS.

---

# 51. Validate Kea Configuration

Before starting Kea, validate the configuration.

Run:

```bash
sudo kea-dhcp4 -t /etc/kea/kea-dhcp4.conf
```

If the configuration is valid, there should be no configuration error.

You can also check:

```bash
sudo kea-dhcp4 -T /etc/kea/kea-dhcp4.conf
```

depending on the installed Kea version.

The exact validation options can vary by Kea release, so the installed command's help can be checked with:

```bash
kea-dhcp4 --help
```

---

# 52. Start Kea DHCPv4

Run:

```bash
sudo systemctl enable kea-dhcp4-server
```

Then:

```bash
sudo systemctl start kea-dhcp4-server
```

Check:

```bash
sudo systemctl status kea-dhcp4-server
```

Expected:

```text
Active: active (running)
```

Ubuntu's documentation also shows restarting the `kea-dhcp4-server` service after configuration changes.

---

# 53. Check Kea Logs

Run:

```bash
sudo journalctl -u kea-dhcp4-server
```

For live logs:

```bash
sudo journalctl -u kea-dhcp4-server -f
```

Press:

```text
Ctrl + C
```

to stop following the logs.

---

# PART F
# TEST DHCP CLIENT

---

# 54. Release Existing DHCP Lease

On client01:

```bash
sudo dhclient -r enp0s8
```

If `dhclient` is not installed, install an appropriate DHCP client utility or use NetworkManager/systemd-networkd/Netplan to trigger DHCP renewal.

---

# 55. Request DHCP Address

For a traditional DHCP client utility:

```bash
sudo dhclient -v enp0s8
```

The client should request an address.

Expected address:

```text
192.168.56.100
```

or another address from:

```text
192.168.56.100 - 192.168.56.200
```

---

# 56. Check Client IP

Run:

```bash
ip addr show enp0s8
```

Expected:

```text
inet 192.168.56.100/24
```

The exact IP may differ.

For example:

```text
192.168.56.101
```

is also valid.

---

# 57. Check DHCP Lease

On dhcp01:

```bash
sudo cat /var/lib/kea/dhcp4.leases
```

You should see lease information associated with the client.

---

# 58. Check Network Configuration

On client01:

```bash
ip addr
```

Check route:

```bash
ip route
```

Check DNS:

```bash
resolvectl status
```

The client should have received DHCP-provided network information.

---

# 59. Test the DHCP Server

From client01:

```bash
ping -c 4 192.168.56.10
```

Then test the gateway:

```bash
ping -c 4 192.168.56.1
```

If Internet routing is configured appropriately, test:

```bash
ping -c 4 8.8.8.8
```

---

# 60. Observe DHCP DORA

On client01:

```bash
sudo dhclient -v enp0s8
```

You should see messages corresponding to:

```text
DHCPDISCOVER
DHCPOFFER
DHCPREQUEST
DHCPACK
```

This is one of the most useful demonstrations in the lab.

---

# PART G
# DHCP RESERVATION

---

# 61. Find Client MAC Address

On client01:

```bash
ip link show enp0s8
```

Example:

```text
link/ether 08:00:27:12:34:56
```

Record the MAC address.

---

# 62. Configure Reservation

A reservation can associate:

```text
MAC
   |
   v
Specific IP
```

Example:

```text
08:00:27:12:34:56
        |
        v
192.168.56.50
```

In Kea, this is configured using a host reservation.

For example:

```json
"reservations": [
  {
    "hw-address": "08:00:27:12:34:56",
    "ip-addresses": [
      "192.168.56.50"
    ]
  }
]
```

This reservation would normally be placed within the relevant subnet configuration.

After changing the configuration, restart or reload Kea.

---

# 63. Test Reservation

On client01:

```bash
sudo dhclient -r enp0s8
```

Then:

```bash
sudo dhclient -v enp0s8
```

Check:

```bash
ip addr show enp0s8
```

The client should receive:

```text
192.168.56.50
```

instead of an address from:

```text
192.168.56.100-200
```

---

# PART H
# INSTALL VAGRANT

---

# 64. Why Vagrant?

The manual process requires creating:

```text
dhcp01
client01
```

through VirtualBox.

Vagrant allows the VM infrastructure to be described using:

```text
Vagrantfile
```

For example:

```text
Vagrantfile
     |
     +---- dhcp01
     |
     +---- client01
```

---

# 65. Install Vagrant

Install Vagrant on Windows.

Verify:

```powershell
vagrant --version
```

---

# 66. Create Vagrant Project

Open PowerShell:

```powershell
mkdir D:\dhcp-lab
cd D:\dhcp-lab
```

Run:

```powershell
vagrant init
```

This creates:

```text
Vagrantfile
```

---

# 67. Vagrantfile

Use:

```ruby
Vagrant.configure("2") do |config|

  config.vm.define "dhcp01" do |dhcp|
    dhcp.vm.box = "ubuntu/jammy64"
    dhcp.vm.hostname = "dhcp01"

    dhcp.vm.network "private_network",
      ip: "192.168.56.10"

    dhcp.vm.provider "virtualbox" do |vb|
      vb.name = "dhcp01"
      vb.memory = 2048
      vb.cpus = 2
    end
  end

  config.vm.define "client01" do |client|
    client.vm.box = "ubuntu/jammy64"
    client.vm.hostname = "client01"

    client.vm.network "private_network",
      type: "dhcp"

    client.vm.provider "virtualbox" do |vb|
      vb.name = "client01"
      vb.memory = 2048
      vb.cpus = 2
    end
  end

end
```

### Important laboratory note

The `private_network` DHCP behavior of Vagrant/VirtualBox can conflict with the objective of demonstrating **Kea as the DHCP server**.

For a clean DHCP lab, the preferred approach is:

```text
VirtualBox Host-only network
        |
        +-- VirtualBox DHCP disabled
        |
        +-- Kea provides DHCP
```

Therefore, for the actual DHCP experiment, the client VM should be attached to the same host-only network while the VirtualBox DHCP server is disabled.

---

# 68. Create the VMs

Run:

```powershell
vagrant up
```

Check:

```powershell
vagrant status
```

---

# 69. SSH to dhcp01

```powershell
vagrant ssh dhcp01
```

Check:

```bash
hostname
```

Expected:

```text
dhcp01
```

---

# 70. SSH to client01

Exit:

```bash
exit
```

Then:

```powershell
vagrant ssh client01
```

Check:

```bash
hostname
```

Expected:

```text
client01
```

---

# 71. Vagrant Commands

Start:

```powershell
vagrant up
```

Stop:

```powershell
vagrant halt
```

Restart:

```powershell
vagrant reload
```

Status:

```powershell
vagrant status
```

SSH:

```powershell
vagrant ssh dhcp01
```

Destroy:

```powershell
vagrant destroy
```

---

# PART I
# INSTALL ANSIBLE IN WSL

---

# 72. Start WSL

From PowerShell:

```powershell
wsl
```

Or open Ubuntu.

---

# 73. Install Ansible

```bash
sudo apt update
```

Then:

```bash
sudo apt install ansible -y
```

Check:

```bash
ansible --version
```

Install SSH:

```bash
sudo apt install openssh-client -y
```

---

# PART J
# CONFIGURE SSH

---

# 74. Generate SSH Key

Inside WSL:

```bash
ssh-keygen
```

Press Enter to accept the default location.

Example:

```text
~/.ssh/id_ed25519
```

---

# 75. Test SSH

For the lab VMs:

```bash
ssh admin@192.168.56.10
```

and:

```bash
ssh admin@192.168.56.20
```

The exact SSH user and connection details depend on how the VMs were provisioned.

---

# PART K
# ANSIBLE INVENTORY

---

# 76. Create Project

Inside WSL:

```bash
mkdir -p ~/dhcp-lab/ansible
cd ~/dhcp-lab/ansible
```

Create:

```text
inventory.ini
dhcp.yml
client.yml
```

---

# 77. inventory.ini

Use:

```ini
[dhcp]
dhcp01 ansible_host=192.168.56.10

[clients]
client01 ansible_host=192.168.56.20

[all:vars]
ansible_user=admin
```

---

# 78. Test Ansible

Run:

```bash
ansible all -i inventory.ini -m ping
```

Expected:

```text
dhcp01 | SUCCESS => {
    "ping": "pong"
}

client01 | SUCCESS => {
    "ping": "pong"
}
```

---

# PART L
# AUTOMATE KEA DHCP SERVER

---

# 79. Create dhcp.yml

Create:

```bash
nano dhcp.yml
```

Use:

```yaml
---
- name: Configure Kea DHCP Server
  hosts: dhcp
  become: true

  tasks:

    - name: Update apt cache
      ansible.builtin.apt:
        update_cache: true
        cache_valid_time: 3600

    - name: Install Kea DHCP
      ansible.builtin.apt:
        name:
          - kea
        state: present

    - name: Configure Kea DHCPv4
      ansible.builtin.copy:
        dest: /etc/kea/kea-dhcp4.conf
        owner: root
        group: root
        mode: '0644'
        content: |
          {
            "Dhcp4": {
              "interfaces-config": {
                "interfaces": [ "enp0s8" ]
              },

              "lease-database": {
                "type": "memfile",
                "persist": true,
                "name": "/var/lib/kea/dhcp4.leases"
              },

              "valid-lifetime": 3600,
              "renew-timer": 1800,
              "rebind-timer": 3150,

              "subnet4": [
                {
                  "id": 1,
                  "subnet": "192.168.56.0/24",

                  "pools": [
                    {
                      "pool": "192.168.56.100 - 192.168.56.200"
                    }
                  ],

                  "option-data": [
                    {
                      "name": "subnet-mask",
                      "data": "255.255.255.0"
                    },
                    {
                      "name": "routers",
                      "data": "192.168.56.1"
                    },
                    {
                      "name": "domain-name-servers",
                      "data": "8.8.8.8"
                    }
                  ]
                }
              ]
            }
          }

    - name: Enable Kea DHCPv4
      ansible.builtin.systemd:
        name: kea-dhcp4-server
        enabled: true
        state: restarted
```

---

# 80. Run Ansible

Run:

```bash
ansible-playbook -i inventory.ini dhcp.yml
```

Ansible will:

```text
Update apt
   |
   v
Install Kea
   |
   v
Create configuration
   |
   v
Enable service
   |
   v
Restart DHCP
```

---

# 81. Verify Kea

Run:

```bash
ansible dhcp -i inventory.ini \
  -a "systemctl status kea-dhcp4-server --no-pager"
```

Expected:

```text
Active: active (running)
```

---

# PART M
# AUTOMATE DHCP CLIENT

---

# 82. client.yml

Create:

```bash
nano client.yml
```

Example:

```yaml
---
- name: Configure DHCP Client
  hosts: clients
  become: true

  tasks:

    - name: Install DHCP client utilities
      ansible.builtin.apt:
        name:
          - isc-dhcp-client
        state: present
        update_cache: true

    - name: Release existing DHCP lease
      ansible.builtin.command:
        cmd: dhclient -r enp0s8
      changed_when: false
      failed_when: false

    - name: Request DHCP lease
      ansible.builtin.command:
        cmd: dhclient -v enp0s8

    - name: Display IP configuration
      ansible.builtin.command:
        cmd: ip addr show enp0s8
      register: ip_output
      changed_when: false

    - name: Show IP configuration
      ansible.builtin.debug:
        var: ip_output.stdout
```

---

# 83. Run Client Playbook

```bash
ansible-playbook -i inventory.ini client.yml
```

The client should obtain an address from:

```text
192.168.56.100 - 192.168.56.200
```

---

# PART N
# VERIFY DHCP AUTOMATION

---

# 84. Check Client IP

Run:

```bash
ansible clients -i inventory.ini \
  -a "ip addr show enp0s8"
```

Look for:

```text
inet 192.168.56.xxx/24
```

where:

```text
100 <= xxx <= 200
```

---

# 85. Check DHCP Leases

On dhcp01:

```bash
sudo cat /var/lib/kea/dhcp4.leases
```

The lease database should contain the assigned address and client information.

---

# 86. Check DHCP Logs

Run:

```bash
sudo journalctl -u kea-dhcp4-server
```

For live monitoring:

```bash
sudo journalctl -u kea-dhcp4-server -f
```

Then renew the client lease.

You should see DHCP activity.

---

# 87. Complete Automated Architecture

```text
                       Windows 11
                           |
              +------------+------------+
              |                         |
        Oracle VirtualBox             WSL2
              |                       Ubuntu
              |                         |
              |                  +------+------+
              |                  |             |
              |               Vagrant       Ansible
              |                                |
              |                                |
              +----------------+---------------+
                               |
                     Host-only Network
                      192.168.56.0/24
                               |
                   +-----------+-----------+
                   |                       |
                   v                       v
                dhcp01                 client01
             192.168.56.10              DHCP
                   |                       |
                   |                       |
                 Kea                  DHCP Client
                   |
                   |
             DHCP Pool
        192.168.56.100-200
```

---

# PART O
# MANUAL VS AUTOMATED DHCP

---

# 88. Manual Process

```text
Create VM
   |
Configure networking
   |
Install Ubuntu
   |
Install Kea
   |
Edit kea-dhcp4.conf
   |
Validate
   |
Start Kea
   |
Configure client
   |
Request DHCP lease
   |
Verify IP
```

---

# 89. Automated Process

```text
Vagrantfile
    |
    v
Create VMs
    |
    v
Ansible
    |
    +-- Install Kea
    |
    +-- Configure DHCP
    |
    +-- Start service
    |
    +-- Configure client
    |
    +-- Request lease
    |
    v
DHCP Lab
```

---

# PART P
# DHCP TROUBLESHOOTING

---

# 90. Client Does Not Receive an IP

On client01:

```bash
ip addr
```

Check the DHCP interface.

Then:

```bash
sudo dhclient -v enp0s8
```

Look for:

```text
DHCPDISCOVER
```

If there is no:

```text
DHCPOFFER
```

check the server.

---

# 91. Check Kea Service

On dhcp01:

```bash
sudo systemctl status kea-dhcp4-server
```

If inactive:

```bash
sudo systemctl restart kea-dhcp4-server
```

---

# 92. Check Kea Logs

```bash
sudo journalctl -u kea-dhcp4-server
```

Look for:

```text
configuration error
interface error
address pool error
permission error
```

---

# 93. Check DHCP Interface

Run:

```bash
ip addr
```

Make sure the configured interface:

```text
enp0s8
```

actually exists.

The interface may have a different name, such as:

```text
enp0s9
```

or another predictable network interface name.

If the interface name is wrong in:

```text
/etc/kea/kea-dhcp4.conf
```

Kea will not receive DHCP requests on the intended network.

---

# 94. Check VirtualBox DHCP

This is extremely important.

If VirtualBox's built-in DHCP server is enabled on the same network, it may answer DHCP requests.

For this lab:

```text
VirtualBox DHCP:
DISABLED
```

Our DHCP server:

```text
Kea:
ENABLED
```

The architecture should be:

```text
client01
   |
   +----------------+
                    |
              Host-only network
                    |
             +------+------+
             |             |
       VirtualBox DHCP   Kea DHCP
          disabled       enabled
```

---

# 95. Check DHCP Pool

The configured pool is:

```text
192.168.56.100
-
192.168.56.200
```

There are:

```text
101
```

addresses in this range.

If all addresses are allocated, new clients cannot receive addresses until leases are released or expire.

---

# 96. Check Lease Database

Run:

```bash
sudo cat /var/lib/kea/dhcp4.leases
```

This allows you to see active lease information.

---

# 97. Check Firewall

Check:

```bash
sudo ufw status
```

If UFW is enabled, DHCP traffic must be permitted appropriately.

DHCP uses:

```text
UDP 67
UDP 68
```

---

# PART Q
# DHCP PACKET ANALYSIS

---

# 98. Install tcpdump

On dhcp01:

```bash
sudo apt install tcpdump -y
```

Capture DHCP traffic:

```bash
sudo tcpdump -i enp0s8 -n port 67 or port 68
```

Now renew the client lease:

```bash
sudo dhclient -r enp0s8
sudo dhclient -v enp0s8
```

You can observe DHCP traffic.

---

# 99. DHCP Packet Flow

The packet capture should conceptually correspond to:

```text
DHCPDISCOVER
      |
      v
DHCPOFFER
      |
      v
DHCPREQUEST
      |
      v
DHCPACK
```

This gives practical visibility into the DORA process.

---

# PART R
# DHCP RESERVATION LAB

---

# 100. Reservation Architecture

Suppose:

```text
Client MAC:
08:00:27:AA:BB:CC
```

should always receive:

```text
192.168.56.50
```

Then:

```text
MAC Address
     |
     v
DHCP Server
     |
     v
192.168.56.50
```

---

# 101. Reservation Configuration

Inside the relevant Kea subnet:

```json
"reservations": [
  {
    "hw-address": "08:00:27:AA:BB:CC",
    "ip-addresses": [
      "192.168.56.50"
    ]
  }
]
```

After changing the configuration:

```bash
sudo systemctl restart kea-dhcp4-server
```

Then renew the client's lease.

---

# PART S
# MULTIPLE DHCP NETWORKS

---

# 102. Multiple Subnets

Kea can serve multiple IPv4 subnets.

For example:

```text
Network 1:
192.168.56.0/24

Network 2:
192.168.57.0/24

Network 3:
192.168.58.0/24
```

Configuration concept:

```json
"subnet4": [
  {
    "id": 1,
    "subnet": "192.168.56.0/24",
    "pools": [
      {
        "pool": "192.168.56.100 - 192.168.56.200"
      }
    ]
  },

  {
    "id": 2,
    "subnet": "192.168.57.0/24",
    "pools": [
      {
        "pool": "192.168.57.100 - 192.168.57.200"
      }
    ]
  }
]
```

Kea supports multiple IPv4 subnet definitions through `subnet4`.

---

# PART T
# DHCP RELAY LAB

---

# 103. DHCP Relay Architecture

Create:

```text
Network A
192.168.56.0/24
        |
        |
    DHCP Client
        |
        v
     Router
   DHCP Relay
        |
        |
Network B
192.168.57.0/24
        |
        v
    DHCP Server
```

The DHCP server can then provide addresses for clients on different subnets through DHCP relay.

This is an important enterprise networking topic.

---

# PART U
# DHCP AND DNS INTEGRATION

---

# 104. Combined Architecture

The DNS and DHCP labs can eventually be combined.

```text
                    Network
                       |
             +---------+---------+
             |                   |
             v                   v
          DHCP01               DNS01
       192.168.56.10       192.168.56.20
             |                   |
             |                   |
             +---------+---------+
                       |
                       v
                    Client
                       |
                       v
                 DHCP Address
                       |
                       v
                   DNS Server
```

DHCP provides:

```text
IP
Subnet
Gateway
DNS server
```

DNS provides:

```text
Hostname -> IP
IP -> Hostname
```

---

# 105. DHCP + DNS Workflow

A client joins the network:

```text
1. Client starts
       |
       v
2. DHCPDISCOVER
       |
       v
3. DHCP Server
       |
       v
4. IP address assigned
       |
       v
5. DNS server information assigned
       |
       v
6. Client performs DNS queries
```

---

# 106. Dynamic DNS

An advanced implementation can combine:

```text
DHCP
+
DNS
```

When DHCP assigns:

```text
192.168.56.100
```

the DHCP system can update DNS:

```text
client01.lab.local
        |
        v
192.168.56.100
```

Kea includes a DHCP-DDNS component for this type of integration.

---

# PART V
# PRACTICAL EXERCISES

---

# Exercise 1: Change the DHCP Pool

Change:

```text
192.168.56.100-200
```

to:

```text
192.168.56.150-180
```

Restart Kea.

Renew the client lease.

Verify the new address.

---

# Exercise 2: Change Lease Time

Change:

```text
valid-lifetime
```

from:

```text
3600
```

to:

```text
600
```

which represents:

```text
10 minutes
```

Observe the lease information.

---

# Exercise 3: Add DNS Option

Configure the DHCP server to provide:

```text
8.8.8.8
1.1.1.1
```

as DNS servers.

Verify on client01:

```bash
resolvectl status
```

---

# Exercise 4: Add Domain Name

Configure:

```text
lab.local
```

as the DHCP-provided domain name.

Verify the client's resolver configuration.

---

# Exercise 5: DHCP Reservation

Reserve:

```text
192.168.56.50
```

for client01.

Verify that client01 always receives:

```text
192.168.56.50
```

---

# Exercise 6: Add Another Client

Create:

```text
client02
```

Configure it as a DHCP client.

Verify that:

```text
client01 -> one DHCP address
client02 -> another DHCP address
```

---

# Exercise 7: Observe DORA

Run:

```bash
sudo tcpdump -i enp0s8 -n port 67 or port 68
```

Then renew the client lease.

Identify:

```text
DHCPDISCOVER
DHCPOFFER
DHCPREQUEST
DHCPACK
```

---

# Exercise 8: Exhaust the DHCP Pool

Create enough clients to consume the entire pool.

Observe what happens when no address remains.

Then release a lease and observe how the address becomes available again.

---

# Exercise 9: Ansible DHCP Configuration

Modify:

```text
dhcp.yml
```

to change:

```text
192.168.56.100-200
```

to:

```text
192.168.56.120-180
```

Run:

```bash
ansible-playbook -i inventory.ini dhcp.yml
```

Verify the client receives an address from the new range.

---

# Exercise 10: Destroy and Rebuild

Destroy the Vagrant environment:

```powershell
vagrant destroy -f
```

Recreate:

```powershell
vagrant up
```

Run the Ansible playbook:

```bash
ansible-playbook -i inventory.ini dhcp.yml
```

Configure the client:

```bash
ansible-playbook -i inventory.ini client.yml
```

Verify DHCP.

This demonstrates:

```text
Infrastructure as Code
+
Configuration Management
```

---

# PART W
# TROUBLESHOOTING CHECKLIST

---

# 107. DHCP Server Checklist

On dhcp01:

```bash
hostname
```

Should be:

```text
dhcp01
```

Check IP:

```bash
ip addr
```

Should include:

```text
192.168.56.10
```

Check Kea:

```bash
sudo systemctl status kea-dhcp4-server
```

Check configuration:

```bash
sudo cat /etc/kea/kea-dhcp4.conf
```

Check logs:

```bash
sudo journalctl -u kea-dhcp4-server
```

Check leases:

```bash
sudo cat /var/lib/kea/dhcp4.leases
```

---

# 108. DHCP Client Checklist

On client01:

```bash
hostname
```

Check interface:

```bash
ip addr
```

Request lease:

```bash
sudo dhclient -v enp0s8
```

Check route:

```bash
ip route
```

Check DNS:

```bash
resolvectl status
```

---

# 109. VirtualBox Checklist

Verify:

```text
Adapter 1:
NAT

Adapter 2:
Host-only
```

Verify:

```text
Host-only DHCP:
Disabled
```

Both VMs must use the same host-only network.

---

# 110. Ansible Checklist

From WSL:

```bash
ansible --version
```

Test:

```bash
ansible all -i inventory.ini -m ping
```

Run:

```bash
ansible-playbook -i inventory.ini dhcp.yml
```

Check:

```bash
ansible dhcp -i inventory.ini \
-a "systemctl status kea-dhcp4-server --no-pager"
```

---

# PART X
# PROJECT DIRECTORY

---

# 111. Windows Project

```text
D:\dhcp-lab\
│
├── Vagrantfile
│
└── ansible\
    ├── inventory.ini
    ├── dhcp.yml
    └── client.yml
```

---

# 112. WSL Project

```text
~/dhcp-lab/
│
└── ansible/
    ├── inventory.ini
    ├── dhcp.yml
    └── client.yml
```

---

# PART Y
# IMPORTANT COMMANDS

---

## Windows

```powershell
wsl --status
wsl -l -v

VBoxManage --version

vagrant --version
vagrant up
vagrant status
vagrant ssh dhcp01
vagrant ssh client01
vagrant halt
vagrant destroy
```

---

## WSL Ubuntu

```bash
sudo apt update
sudo apt upgrade -y

ansible --version
ssh -V

ansible all -i inventory.ini -m ping

ansible-playbook -i inventory.ini dhcp.yml

ansible-playbook -i inventory.ini client.yml
```

---

## DHCP Server

```bash
hostname
ip addr

sudo apt install kea -y

sudo systemctl status kea-dhcp4-server
sudo systemctl restart kea-dhcp4-server

sudo journalctl -u kea-dhcp4-server

sudo cat /var/lib/kea/dhcp4.leases
```

---

## DHCP Client

```bash
ip addr
ip route

sudo dhclient -r enp0s8
sudo dhclient -v enp0s8

resolvectl status
```

---

## Packet Capture

```bash
sudo tcpdump -i enp0s8 -n port 67 or port 68
```

---

# PART Z
# FINAL LAB ARCHITECTURE

The completed DHCP environment is:

```text
                         WINDOWS 11
                              |
              +---------------+---------------+
              |                               |
       Oracle VirtualBox                    WSL2
              |                             Ubuntu
              |                               |
              |                       +-------+-------+
              |                       |               |
              |                    Vagrant         Ansible
              |                                       |
              +-------------------+-------------------+
                                  |
                         Host-only Network
                          192.168.56.0/24
                                  |
                    +-------------+-------------+
                    |                           |
                    v                           v
                 dhcp01                      client01
              192.168.56.10                    DHCP
                    |                           |
                    |                           |
                  Kea                    DHCP Client
                    |
                    |
             DHCP Configuration
                    |
          +---------+----------+
          |                    |
          v                    v
       DHCP Pool           DHCP Options
    192.168.56.100       Subnet Mask
        -                Gateway
    192.168.56.200       DNS
                         Lease Time
```

---

# 113. Complete DHCP Workflow

The complete learning workflow is:

```text
DHCP CONCEPTS
      |
      v
DHCP Client
      |
      v
DHCP Server
      |
      v
DORA
      |
      v
DHCP Pool
      |
      v
Lease
      |
      v
DHCP Options
      |
      v
Reservations
      |
      v
DHCP Relay
      |
      v
Kea
      |
      v
Manual Configuration
      |
      v
Vagrant
      |
      v
Ansible
      |
      v
Automated DHCP Lab
```

---

# 114. Manual Learning Path

First perform:

```text
1. Install Windows software
2. Install WSL2
3. Install VirtualBox
4. Create dhcp01 manually
5. Create client01 manually
6. Configure static server IP
7. Configure client DHCP
8. Install Kea
9. Configure kea-dhcp4.conf
10. Start Kea
11. Request DHCP lease
12. Verify address
13. Observe DORA
14. Inspect lease database
15. Capture DHCP packets
```

This establishes the underlying DHCP concepts.

---

# 115. Automation Learning Path

Then rebuild the same environment using:

```text
1. Vagrant
2. Vagrantfile
3. WSL2 Ubuntu
4. Ansible
5. Inventory
6. SSH
7. DHCP playbook
8. Client playbook
9. Automated verification
```

The important principle is:

```text
Understand manually
        |
        v
Automate
        |
        v
Rebuild
        |
        v
Test
```

---

# 116. Advanced DHCP Topics

After completing this lab, continue with:

```text
DHCP reservations
DHCP relay
Multiple subnets
Multiple DHCP pools
DHCP failover/high availability
DHCPv6
PXE boot
Network booting
Dynamic DNS
DHCP security
DHCP monitoring
DHCP packet analysis
Kea Control Agent
Kea databases
PostgreSQL-backed leases
Ansible DHCP roles
```

Kea supports lease databases including a simple persistent memfile backend and database-backed configurations, while its DHCPv4 configuration supports multiple subnet and pool definitions.

---

# 117. DHCP + DNS + Linux Administration Project

The DHCP lab can then be combined with the previous DNS lab.

Final infrastructure:

```text
                         Windows 11
                              |
                 +------------+------------+
                 |                         |
             VirtualBox                  WSL2
                 |                     Ubuntu
                 |                         |
                 |                 Vagrant + Ansible
                 |                         |
                 +------------+------------+
                              |
                       Lab Network
                     192.168.56.0/24
                              |
          +-------------------+-------------------+
          |                   |                   |
          v                   v                   v
       dhcp01              dns01              client01
    192.168.56.10      192.168.56.20             DHCP
          |                   |                   |
          |                   |                   |
         Kea                BIND9            DHCP Client
          |                   |                   |
          +---------+---------+-------------------+
                    |
                    v
              Network Services
```

DHCP:

```text
Client -> IP configuration
```

DNS:

```text
Name -> IP
IP -> Name
```

Ansible:

```text
Automates configuration
```

Vagrant:

```text
Automates VM provisioning
```

VirtualBox:

```text
Provides virtual machines and networking
```

WSL:

```text
Provides Linux control environment on Windows
```

---

# 118. Official Documentation

Ubuntu DHCP overview: [Ubuntu DHCP documentation](https://ubuntu.com/server/docs/explanation/networking/about-dhcp/)

Ubuntu Kea installation and configuration: [Ubuntu Kea DHCP documentation](https://ubuntu.com/server/docs/how-to/install-and-configure-isc-kea/)

ISC Kea DHCPv4 documentation: [ISC Kea DHCPv4 documentation](https://kea.readthedocs.io/en/latest/arm/dhcp4-srv.html)

Kea configuration examples: [Kea configuration examples](https://kea.readthedocs.io/en/latest/config-examples.html)

Ubuntu networking documentation: [Ubuntu Server networking documentation](https://ubuntu.com/server/docs/how-to/networking/)

---

# 119. Expected Final Result

At the end of the lab:

```text
DHCP Server
     |
     | 192.168.56.10
     |
     | Kea
     |
     | DHCP Pool
     |
     +------------------------------+
                                    |
                                    v
                              DHCP Client
                                    |
                              DHCPDISCOVER
                                    |
                              DHCPOFFER
                                    |
                              DHCPREQUEST
                                    |
                              DHCPACK
                                    |
                                    v
                              Client receives
                              192.168.56.100+
```

The client should be able to demonstrate:

```text
IP address obtained automatically
Subnet mask obtained automatically
Gateway obtained automatically
DNS server obtained automatically
Lease information
DHCP renewal
DHCP release
DHCP reservation
```

The administrator should also be able to observe the complete process using:

```text
ip addr
ip route
resolvectl
dhclient
journalctl
tcpdump
```

and automate the same configuration using:

```text
Vagrant
+
Ansible
+
Kea
```