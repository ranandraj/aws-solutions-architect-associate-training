# DNS Server Administration Lab on Windows 11
## Ubuntu Server, Oracle VirtualBox, WSL2, Vagrant and Ansible

---

# 1. Introduction

The Domain Name System (DNS) is one of the fundamental services in computer networks.

DNS converts human-readable hostnames such as:

```text
www.example.com
```

into IP addresses such as:

```text
93.184.216.34
```

Computers communicate using IP addresses, while humans generally use names.

For example:

```text
client01.lab.local
        |
        | DNS query
        v
192.168.56.20
```

In this laboratory, a complete DNS environment will be created using:

- Windows 11 as the host operating system
- WSL2 with Ubuntu as the automation workstation
- Oracle VirtualBox as the virtualization platform
- Vagrant for VM provisioning
- Ansible for configuration automation
- Ubuntu Server as the guest operating system
- BIND9 as the DNS server
- Two Ubuntu Server virtual machines

---

# 2. Lab Objectives

After completing this lab, the environment will contain:

```text
                         Windows 11
                             |
             +---------------+---------------+
             |                               |
       Oracle VirtualBox                  WSL2
             |                           Ubuntu
             |                               |
       +-----+-----+                         |
       |           |                         |
    dns01       client01              Ansible Control Node
       |           |                         |
       |           +-------------------------+
       |
    BIND9
    DNS Server
```

The two virtual machines will be:

| VM | Purpose | IP Address |
|---|---|---|
| dns01 | DNS server | 192.168.56.10 |
| client01 | DNS client | 192.168.56.20 |

DNS domain:

```text
lab.local
```

Forward DNS zone:

```text
lab.local
```

Reverse DNS zone:

```text
56.168.192.in-addr.arpa
```

The final DNS records will include:

```text
dns01.lab.local     -> 192.168.56.10
client01.lab.local  -> 192.168.56.20
```

and reverse mappings:

```text
192.168.56.10 -> dns01.lab.local
192.168.56.20 -> client01.lab.local
```

---

# 3. Software Architecture

The lab uses four important technologies.

## 3.1 Windows 11

Windows is the physical host operating system.

It provides the hardware resources:

- CPU
- RAM
- Storage
- Network

---

# 3.2 Oracle VirtualBox

Oracle VirtualBox provides virtualization.

It creates and runs the Ubuntu Server virtual machines.

Conceptually:

```text
Windows 11
    |
    v
VirtualBox
    |
    +---- Ubuntu Server dns01
    |
    +---- Ubuntu Server client01
```

Vagrant can use VirtualBox as its provider. HashiCorp documents VirtualBox as a supported Vagrant provider.

---

# 3.3 WSL2 Ubuntu

WSL2 provides a Linux environment directly inside Windows.

It will be used as the Ansible control node.

```text
Windows 11
   |
   +-- WSL2
       |
       +-- Ubuntu
           |
           +-- Ansible
           |
           +-- SSH client
```

Ansible cannot use native Windows as its normal control node. Ansible documentation recommends a UNIX-like environment and specifically supports using WSL on Windows for this purpose.

---

# 3.4 Vagrant

Vagrant automates virtual machine provisioning.

Instead of manually creating every VM through the VirtualBox GUI, a `Vagrantfile` describes the infrastructure.

Example:

```text
Vagrantfile
     |
     +---- dns01
     |
     +---- client01
```

Vagrant then creates the virtual machines.

---

# 3.5 Ansible

Ansible configures the operating systems and applications.

For example:

```text
Ansible
   |
   +---- Install BIND9
   |
   +---- Configure named.conf
   |
   +---- Create DNS zone
   |
   +---- Create DNS records
   |
   +---- Start BIND9
```

Ansible is therefore used for **configuration management**, while Vagrant is used primarily for **VM provisioning**.

The managed Ubuntu systems do not need Ansible installed. They need SSH access and Python for normal Ansible module execution.

---

# 4. Understanding DNS

## 4.1 What is DNS?

DNS stands for:

```text
Domain Name System
```

DNS provides a distributed naming system for computers and services.

For example:

```text
www.example.com
```

can resolve to:

```text
203.0.113.10
```

Instead of remembering:

```text
203.0.113.10
```

users can access:

```text
www.example.com
```

---

# 5. DNS Name Hierarchy

DNS uses a hierarchical namespace.

Example:

```text
www.example.com.
```

The hierarchy is:

```text
.
|
+-- com
    |
    +-- example
        |
        +-- www
```

The final dot represents the DNS root.

```text
www.example.com.
```

contains:

```text
www       = hostname
example   = domain
com       = top-level domain
.         = root
```

---

# 6. DNS Components

Important DNS components include:

## 6.1 DNS Client

The machine requesting DNS information.

Example:

```text
client01
```

---

## 6.2 DNS Resolver

A resolver receives a query from a client and finds the answer.

For example:

```text
client01
   |
   | What is the IP of www.example.com?
   v
DNS resolver
```

---

## 6.3 Authoritative DNS Server

An authoritative DNS server contains the actual DNS data for a zone.

For example:

```text
lab.local
```

The DNS server in this lab will be authoritative for:

```text
lab.local
```

BIND describes an authoritative server as a server providing authoritative answers for the zones it supports. A server can support one or many zones.

---

# 7. Forward DNS Lookup

Forward lookup means:

```text
Hostname -> IP address
```

Example:

```text
client01.lab.local
        |
        v
192.168.56.20
```

The main DNS records used are:

```text
A
AAAA
```

An A record stores an IPv4 address.

Example:

```text
client01.lab.local. IN A 192.168.56.20
```

---

# 8. Reverse DNS Lookup

Reverse DNS performs:

```text
IP address -> hostname
```

Example:

```text
192.168.56.20
       |
       v
client01.lab.local
```

IPv4 reverse DNS uses:

```text
in-addr.arpa
```

For:

```text
192.168.56.20
```

the reverse DNS name becomes:

```text
20.56.168.192.in-addr.arpa
```

The DNS record used is:

```text
PTR
```

Example:

```text
20 IN PTR client01.lab.local.
```

---

# 9. DNS Resource Records

Common DNS records include:

| Record | Purpose |
|---|---|
| A | IPv4 address |
| AAAA | IPv6 address |
| CNAME | Alias |
| MX | Mail server |
| NS | Authoritative name server |
| PTR | Reverse DNS |
| SOA | Start of Authority |
| TXT | Text information |
| SRV | Service location |

---

# 10. A Record

Example:

```text
client01 IN A 192.168.56.20
```

Meaning:

```text
client01.lab.local
        |
        v
192.168.56.20
```

---

# 11. PTR Record

Example:

```text
20 IN PTR client01.lab.local.
```

Meaning:

```text
192.168.56.20
        |
        v
client01.lab.local
```

---

# 12. NS Record

NS means:

```text
Name Server
```

Example:

```text
@ IN NS dns01.lab.local.
```

It identifies the authoritative DNS server for the zone.

---

# 13. SOA Record

SOA means:

```text
Start of Authority
```

It contains important information about a DNS zone.

Example:

```text
@ IN SOA dns01.lab.local. admin.lab.local. (
    2026090301
    3600
    1800
    604800
    86400
)
```

Important SOA fields include:

```text
Serial
Refresh
Retry
Expire
Minimum/negative caching TTL
```

The serial number is especially important when using primary and secondary DNS servers.

---

# 14. DNS Zone

A zone is an administratively managed portion of the DNS namespace.

For this laboratory:

```text
lab.local
```

will be a DNS zone.

The zone will contain records such as:

```text
dns01.lab.local
client01.lab.local
```

A DNS server can be authoritative for multiple zones. BIND supports primary and secondary versions of zones.

---

# 15. Forward and Reverse Zones

The lab will have two separate zones.

## Forward zone

```text
lab.local
```

File:

```text
/etc/bind/db.lab.local
```

Purpose:

```text
hostname -> IP
```

---

## Reverse zone

```text
56.168.192.in-addr.arpa
```

File:

```text
/etc/bind/db.192.168.56
```

Purpose:

```text
IP -> hostname
```

---

# 16. Primary and Secondary DNS

A primary DNS server contains the main copy of zone data.

A secondary DNS server obtains its zone data from a primary using zone transfer.

BIND supports:

```text
AXFR
IXFR
```

for zone transfers.

Example:

```text
             Primary DNS
             dns01
          192.168.56.10
                 |
                 | AXFR / IXFR
                 |
                 v
          Secondary DNS
             dns02
          192.168.56.30
```

This current lab uses one DNS server and one DNS client. A secondary DNS server can be added as an advanced exercise.

---

# 17. DNS Forwarding

A DNS server may not know the answer for an external domain.

For example:

```text
google.com
```

The DNS server can forward the query to another resolver.

Conceptually:

```text
client
  |
  v
dns01
  |
  | unknown domain
  v
forwarder
```

BIND supports `forward first` and `forward only`.

---

# 18. DNS Recursion

A recursive DNS server performs queries on behalf of clients.

For example:

```text
client
 |
 | www.example.com?
 v
dns01
 |
 +--> root
 |
 +--> .com
 |
 +--> example.com
 |
 v
IP address
```

In this laboratory BIND can be configured for recursive resolution.

---

# 19. DNS Ports

DNS normally uses:

```text
UDP 53
TCP 53
```

UDP is commonly used for normal DNS queries.

TCP is also required in several DNS operations, including larger responses and zone transfers.

---

# 20. Complete Lab Architecture

The final architecture is:

```text
                         WINDOWS 11
                             |
             +---------------+----------------+
             |                                |
             |                         WSL2 Ubuntu
             |                                |
             |                         Vagrant + Ansible
             |
        Oracle VirtualBox
             |
       Host-only Network
        192.168.56.0/24
             |
       +-----+------+
       |            |
       v            v
    dns01        client01
192.168.56.10  192.168.56.20
       |
       |
     BIND9
       |
       +---- lab.local
       |
       +---- reverse DNS
```

---

# 21. Prerequisites

Recommended Windows computer:

```text
Windows 11 64-bit
CPU: 4 cores or more
RAM: 8 GB or more
Free disk: 40 GB or more
```

Recommended VM resources:

```text
dns01:
    2 CPU
    2 GB RAM
    20 GB disk

client01:
    2 CPU
    2 GB RAM
    20 GB disk
```

---

# 22. Software Required

Install:

1. Oracle VirtualBox
2. Ubuntu Server ISO
3. WSL2
4. Ubuntu WSL application
5. Vagrant
6. Ansible
7. OpenSSH client

Optional:

```text
Git
Visual Studio Code
```

---

# PART A
# INSTALL WSL2 UBUNTU

---

# 23. Check Windows Version

Open:

```text
PowerShell
```

Run:

```powershell
winver
```

Windows 11 should be displayed.

---

# 24. Install WSL

Open PowerShell as Administrator.

Run:

```powershell
wsl --install
```

Restart Windows if requested.

After restarting:

```powershell
wsl --status
```

Expected information will show that WSL is installed.

Check distributions:

```powershell
wsl -l -v
```

Example:

```text
  NAME      STATE           VERSION
* Ubuntu    Running         2
```

The important value is:

```text
VERSION 2
```

---

# 25. Start Ubuntu

From Windows Start Menu:

```text
Ubuntu
```

Open the Ubuntu application.

The first startup may ask for:

```text
UNIX username
password
```

Example:

```text
Enter new UNIX username:
admin
```

Set a password.

The password will not appear while typing.

---

# 26. Update WSL Ubuntu

Inside Ubuntu:

```bash
sudo apt update
```

Then:

```bash
sudo apt upgrade -y
```

Check OS:

```bash
cat /etc/os-release
```

Example:

```text
NAME="Ubuntu"
VERSION="24.04 LTS ..."
```

---

# 27. Check WSL Networking

Run:

```bash
ip addr
```

Example:

```text
1: lo:
2: eth0:
```

Test Internet:

```bash
ping -c 4 8.8.8.8
```

Then:

```bash
ping -c 4 google.com
```

Stop the test with normal command completion.

---

# PART B
# INSTALL ORACLE VIRTUALBOX

---

# 28. Install VirtualBox

Download and install Oracle VirtualBox for Windows.

During installation, allow the required networking components when Windows asks for permission.

After installation open PowerShell:

```powershell
VBoxManage --version
```

Example:

```text
7.x.x
```

The exact version depends on the current VirtualBox release.

Vagrant's VirtualBox provider requires VirtualBox to be installed before using the provider.

---

# 29. Verify Hardware Virtualization

Open:

```text
Task Manager
```

Select:

```text
Performance
CPU
```

Check:

```text
Virtualization: Enabled
```

If virtualization is disabled, enable Intel VT-x or AMD-V/SVM in the computer's UEFI/BIOS.

---

# PART C
# CREATE VIRTUALBOX NETWORK

---

# 30. Why a Host-Only Network?

The DNS server and DNS client need to communicate.

We will create:

```text
192.168.56.0/24
```

with:

```text
dns01       192.168.56.10
client01    192.168.56.20
```

The network will be:

```text
192.168.56.0/24
```

---

# 31. Create Host-Only Adapter

Open:

```text
VirtualBox
```

Go to:

```text
File
    -> Tools
        -> Network Manager
```

Create a Host-only network.

Use approximately:

```text
IPv4 Address:
192.168.56.1

IPv4 Network Mask:
255.255.255.0
```

Disable the DHCP server if manually assigning static IP addresses.

The network becomes:

```text
192.168.56.0/24

Host:
192.168.56.1

dns01:
192.168.56.10

client01:
192.168.56.20
```

---

# PART D
# MANUAL VM CREATION WITHOUT VAGRANT

This section deliberately does not use Vagrant or Ansible.

It teaches the underlying process first.

---

# 32. Download Ubuntu Server ISO

Download an Ubuntu Server ISO from the official Ubuntu website.

Save it somewhere such as:

```text
D:\ISO\ubuntu-server.iso
```

Using a separate drive is useful when the Windows C: drive has limited free space.

---

# 33. Create dns01 Manually

Open VirtualBox.

Select:

```text
New
```

Name:

```text
dns01
```

Type:

```text
Linux
```

Version:

```text
Ubuntu 64-bit
```

Memory:

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

Attach the Ubuntu Server ISO.

---

# 34. Configure dns01 Networking

Use two adapters.

## Adapter 1

```text
Attached to:
NAT
```

Purpose:

```text
Internet access
```

## Adapter 2

```text
Attached to:
Host-only Adapter
```

Select the:

```text
192.168.56.0/24
```

host-only network.

---

# 35. Install Ubuntu Server on dns01

Start the VM.

Install Ubuntu Server.

Set hostname:

```text
dns01
```

Create an administrative user.

Example:

```text
Username:
admin
```

Enable OpenSSH Server during installation if the installer provides the option.

After installation:

```bash
hostname
```

Expected:

```text
dns01
```

---

# 36. Create client01 Manually

Repeat the same process.

VM name:

```text
client01
```

Memory:

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

Networking:

```text
Adapter 1 -> NAT
Adapter 2 -> Host-only
```

Hostname:

```text
client01
```

Install OpenSSH Server.

---

# 37. Check Network Interfaces

On dns01:

```bash
ip addr
```

Example:

```text
enp0s3
enp0s8
```

Usually:

```text
enp0s3 -> NAT
enp0s8 -> Host-only
```

Do not assume the interface names.

Always check:

```bash
ip addr
```

---

# 38. Configure Static IP on dns01

Ubuntu Server uses Netplan.

Find the Netplan file:

```bash
ls /etc/netplan/
```

Example:

```text
50-cloud-init.yaml
```

Edit it:

```bash
sudo nano /etc/netplan/50-cloud-init.yaml
```

Example configuration:

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

You should see:

```text
192.168.56.10/24
```

---

# 39. Configure Static IP on client01

Edit the Netplan configuration:

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
        - 192.168.56.20/24
```

Apply:

```bash
sudo netplan apply
```

Check:

```bash
ip addr
```

Expected:

```text
192.168.56.20/24
```

---

# 40. Test Network Connectivity

From client01:

```bash
ping -c 4 192.168.56.10
```

Expected:

```text
64 bytes from 192.168.56.10
```

From dns01:

```bash
ping -c 4 192.168.56.20
```

Expected:

```text
64 bytes from 192.168.56.20
```

---

# 41. Test Internet Connectivity

On both systems:

```bash
ping -c 4 8.8.8.8
```

Then:

```bash
ping -c 4 ubuntu.com
```

The NAT adapter provides Internet connectivity.

The host-only adapter provides the private lab network.

---

# PART E
# MANUAL BIND9 DNS CONFIGURATION

---

# 42. Install BIND9

Login to dns01.

Run:

```bash
sudo apt update
```

Install:

```bash
sudo apt install bind9 bind9utils dnsutils -y
```

Check service:

```bash
sudo systemctl status bind9
```

Enable at boot:

```bash
sudo systemctl enable bind9
```

---

# 43. Important BIND Files

Important files include:

```text
/etc/bind/named.conf
/etc/bind/named.conf.options
/etc/bind/named.conf.local
```

Zone files:

```text
/etc/bind/db.lab.local
/etc/bind/db.192.168.56
```

---

# 44. Configure BIND Options

Edit:

```bash
sudo nano /etc/bind/named.conf.options
```

Use:

```text
options {
    directory "/var/cache/bind";

    listen-on {
        127.0.0.1;
        192.168.56.10;
    };

    allow-query {
        localhost;
        192.168.56.0/24;
    };

    recursion yes;

    dnssec-validation auto;
};
```

Save:

```text
Ctrl + O
Enter
Ctrl + X
```

---

# 45. Configure Forward Zone

Edit:

```bash
sudo nano /etc/bind/named.conf.local
```

Add:

```text
zone "lab.local" {
    type primary;
    file "/etc/bind/db.lab.local";
};
```

---

# 46. Create Forward Zone File

Create:

```bash
sudo nano /etc/bind/db.lab.local
```

Enter:

```text
$TTL 86400

@   IN  SOA dns01.lab.local. admin.lab.local. (
        2026090301
        3600
        1800
        604800
        86400
)

@           IN  NS      dns01.lab.local.

dns01       IN  A       192.168.56.10
client01    IN  A       192.168.56.20
```

---

# 47. Understanding the Forward Zone File

This line:

```text
$TTL 86400
```

sets the default TTL to:

```text
86400 seconds
```

which is:

```text
24 hours
```

This:

```text
@ IN NS dns01.lab.local.
```

declares dns01 as the authoritative DNS server.

This:

```text
dns01 IN A 192.168.56.10
```

creates:

```text
dns01.lab.local -> 192.168.56.10
```

This:

```text
client01 IN A 192.168.56.20
```

creates:

```text
client01.lab.local -> 192.168.56.20
```

---

# 48. Configure Reverse Zone

Edit:

```bash
sudo nano /etc/bind/named.conf.local
```

Add:

```text
zone "56.168.192.in-addr.arpa" {
    type primary;
    file "/etc/bind/db.192.168.56";
};
```

---

# 49. Create Reverse Zone File

Create:

```bash
sudo nano /etc/bind/db.192.168.56
```

Enter:

```text
$TTL 86400

@   IN  SOA dns01.lab.local. admin.lab.local. (
        2026090301
        3600
        1800
        604800
        86400
)

@       IN  NS      dns01.lab.local.

10      IN  PTR     dns01.lab.local.
20      IN  PTR     client01.lab.local.
```

---

# 50. Understanding Reverse DNS

The network is:

```text
192.168.56.0/24
```

Reverse zone:

```text
56.168.192.in-addr.arpa
```

Therefore:

```text
10
```

means:

```text
10.56.168.192.in-addr.arpa
```

which represents:

```text
192.168.56.10
```

Similarly:

```text
20
```

represents:

```text
192.168.56.20
```

---

# 51. Validate BIND Configuration

Before restarting BIND, always validate the configuration.

Run:

```bash
sudo named-checkconf
```

If there is no output:

```text
Configuration syntax is valid.
```

Check forward zone:

```bash
sudo named-checkzone lab.local /etc/bind/db.lab.local
```

Expected:

```text
zone lab.local/IN: loaded serial 2026090301
OK
```

Check reverse zone:

```bash
sudo named-checkzone 56.168.192.in-addr.arpa /etc/bind/db.192.168.56
```

Expected:

```text
zone 56.168.192.in-addr.arpa/IN: loaded serial 2026090301
OK
```

---

# 52. Restart BIND

Run:

```bash
sudo systemctl restart bind9
```

Check:

```bash
sudo systemctl status bind9
```

Expected:

```text
Active: active (running)
```

---

# 53. Test Forward DNS Locally

On dns01:

```bash
dig @127.0.0.1 dns01.lab.local
```

Then:

```bash
dig @127.0.0.1 client01.lab.local
```

Look for:

```text
ANSWER SECTION
```

Example:

```text
client01.lab.local.    86400    IN    A    192.168.56.20
```

---

# 54. Test Reverse DNS

Run:

```bash
dig @127.0.0.1 -x 192.168.56.20
```

Expected:

```text
ANSWER SECTION

20.56.168.192.in-addr.arpa. 86400 IN PTR client01.lab.local.
```

---

# PART F
# CONFIGURE client01 TO USE dns01

---

# 55. Check Current DNS

On client01:

```bash
resolvectl status
```

Look for:

```text
DNS Servers
```

---

# 56. Temporarily Configure DNS

Identify the host-only interface:

```bash
ip addr
```

Assume:

```text
enp0s8
```

Run:

```bash
sudo resolvectl dns enp0s8 192.168.56.10
```

Configure the search domain:

```bash
sudo resolvectl domain enp0s8 lab.local
```

Check:

```bash
resolvectl status
```

You should see:

```text
DNS Servers: 192.168.56.10
DNS Domain: lab.local
```

---

# 57. Test DNS from client01

Run:

```bash
nslookup dns01.lab.local
```

Expected:

```text
Server:
Address: 192.168.56.10

Name:
dns01.lab.local

Address:
192.168.56.10
```

Test:

```bash
nslookup client01.lab.local
```

Expected:

```text
Name:
client01.lab.local

Address:
192.168.56.20
```

---

# 58. Test Reverse Lookup

Run:

```bash
nslookup 192.168.56.20
```

Expected:

```text
Name:
client01.lab.local

Address:
192.168.56.20
```

---

# 59. Test Using dig

Run:

```bash
dig @192.168.56.10 client01.lab.local
```

Reverse:

```bash
dig @192.168.56.10 -x 192.168.56.20
```

---

# 60. Test the DNS Server from the Client

Run:

```bash
ping client01.lab.local
```

Expected:

```text
PING client01.lab.local (192.168.56.20)
```

Test dns01:

```bash
ping dns01.lab.local
```

Expected:

```text
PING dns01.lab.local (192.168.56.10)
```

The basic DNS lab is now working.

---

# PART G
# INSTALL VAGRANT

---

# 61. Why Vagrant?

The manual process required:

```text
Create VM
Configure CPU
Configure RAM
Configure disk
Configure network
Install OS
Configure hostname
Configure networking
```

Doing this repeatedly is slow.

Vagrant allows the infrastructure to be described using a configuration file.

---

# 62. Install Vagrant on Windows

Install Vagrant on Windows.

After installation open PowerShell:

```powershell
vagrant --version
```

Example:

```text
Vagrant x.x.x
```

Vagrant supports VirtualBox as a provider.

---

# 63. Verify VirtualBox Provider

Run:

```powershell
vagrant plugin list
```

Vagrant's VirtualBox provider is built into Vagrant.

VirtualBox must already be installed.

---

# PART H
# CREATE VAGRANT PROJECT

---

# 64. Create Project Directory

In PowerShell:

```powershell
mkdir D:\dns-lab
cd D:\dns-lab
```

Initialize Vagrant:

```powershell
vagrant init
```

This creates:

```text
Vagrantfile
```

---

# 65. Vagrantfile

Replace the contents with:

```ruby
Vagrant.configure("2") do |config|

  config.vm.define "dns01" do |dns|
    dns.vm.box = "ubuntu/jammy64"
    dns.vm.hostname = "dns01"

    dns.vm.network "private_network",
      ip: "192.168.56.10"

    dns.vm.provider "virtualbox" do |vb|
      vb.name = "dns01"
      vb.memory = 2048
      vb.cpus = 2
    end
  end

  config.vm.define "client01" do |client|
    client.vm.box = "ubuntu/jammy64"
    client.vm.hostname = "client01"

    client.vm.network "private_network",
      ip: "192.168.56.20"

    client.vm.provider "virtualbox" do |vb|
      vb.name = "client01"
      vb.memory = 2048
      vb.cpus = 2
    end
  end

end
```

---

# 66. Start the VMs

From:

```text
D:\dns-lab
```

run:

```powershell
vagrant up
```

Vagrant will:

```text
Download box
      |
      v
Create dns01
      |
      v
Create client01
      |
      v
Configure networking
      |
      v
Start VMs
```

---

# 67. Check VMs

Run:

```powershell
vagrant status
```

Expected:

```text
dns01      running
client01   running
```

---

# 68. Login to dns01

Run:

```powershell
vagrant ssh dns01
```

Check:

```bash
hostname
```

Expected:

```text
dns01
```

Check:

```bash
ip addr
```

Verify:

```text
192.168.56.10
```

---

# 69. Login to client01

Exit dns01:

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

Check:

```bash
ip addr
```

Verify:

```text
192.168.56.20
```

---

# 70. Vagrant VM Commands

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
vagrant ssh dns01
```

Destroy:

```powershell
vagrant destroy
```

Destroy without confirmation:

```powershell
vagrant destroy -f
```

---

# PART I
# INSTALL ANSIBLE IN WSL UBUNTU

---

# 71. Start WSL Ubuntu

From Windows:

```text
Start
 -> Ubuntu
```

Or PowerShell:

```powershell
wsl
```

---

# 72. Update Ubuntu

Inside WSL:

```bash
sudo apt update
```

Then:

```bash
sudo apt upgrade -y
```

---

# 73. Install Ansible

Run:

```bash
sudo apt install ansible -y
```

Check:

```bash
ansible --version
```

Example:

```text
ansible [core ...]
```

Ansible supports Ubuntu and other UNIX-like systems as control nodes, and WSL can provide that Linux environment on Windows.

---

# 74. Install SSH Client

Run:

```bash
sudo apt install openssh-client -y
```

Verify:

```bash
ssh -V
```

---

# PART J
# SSH FROM WSL TO VAGRANT VMs

---

# 75. Understand the Connection

The architecture is:

```text
Windows
   |
   +-- WSL Ubuntu
          |
          | SSH
          |
          +----------> dns01
          |
          +----------> client01
```

Ansible uses SSH to connect to the Linux systems.

---

# 76. Find Vagrant SSH Configuration

From PowerShell:

```powershell
vagrant ssh-config
```

This displays SSH information such as:

```text
Host dns01
  HostName ...
  User vagrant
  Port ...
  IdentityFile ...
```

Vagrant uses its own SSH configuration for VM access.

For a clean Ansible lab, it is often simpler to configure normal SSH access using a known user and SSH key.

---

# 77. Configure SSH Access

Inside the Ubuntu VMs, create/use an administrative account.

Example:

```text
admin
```

On the WSL Ubuntu control node:

```bash
ssh-keygen
```

Accept the default location:

```text
~/.ssh/id_ed25519
```

Copy the key:

```bash
ssh-copy-id admin@192.168.56.10
```

Then:

```bash
ssh-copy-id admin@192.168.56.20
```

Test:

```bash
ssh admin@192.168.56.10
```

Then:

```bash
ssh admin@192.168.56.20
```

---

# 78. Test SSH Connectivity

From WSL:

```bash
ssh admin@192.168.56.10 hostname
```

Expected:

```text
dns01
```

Then:

```bash
ssh admin@192.168.56.20 hostname
```

Expected:

```text
client01
```

---

# PART K
# CREATE ANSIBLE PROJECT

---

# 79. Create Project

Inside WSL:

```bash
mkdir -p ~/dns-lab/ansible
cd ~/dns-lab/ansible
```

Create:

```text
inventory.ini
dns.yml
client.yml
```

Directory:

```text
dns-lab/
└── ansible/
    ├── inventory.ini
    ├── dns.yml
    └── client.yml
```

---

# 80. Create Inventory

Create:

```bash
nano inventory.ini
```

Use:

```ini
[dns]
dns01 ansible_host=192.168.56.10

[clients]
client01 ansible_host=192.168.56.20

[all:vars]
ansible_user=admin
```

---

# 81. Test Ansible

Run:

```bash
ansible all -i inventory.ini -m ping
```

Expected:

```text
dns01 | SUCCESS => {
    "ping": "pong"
}

client01 | SUCCESS => {
    "ping": "pong"
}
```

This confirms:

```text
WSL
 |
 +-- Ansible
      |
      +-- SSH
           |
           +-- dns01
           |
           +-- client01
```

---

# PART L
# AUTOMATE DNS SERVER WITH ANSIBLE

---

# 82. Create dns.yml

Create:

```bash
nano dns.yml
```

Use:

```yaml
---
- name: Configure BIND9 DNS Server
  hosts: dns
  become: true

  handlers:

    - name: Restart BIND9
      ansible.builtin.systemd:
        name: bind9
        state: restarted

  tasks:

    - name: Update apt cache
      ansible.builtin.apt:
        update_cache: true
        cache_valid_time: 3600

    - name: Install BIND9 and DNS utilities
      ansible.builtin.apt:
        name:
          - bind9
          - bind9utils
          - dnsutils
        state: present

    - name: Configure BIND options
      ansible.builtin.copy:
        dest: /etc/bind/named.conf.options
        owner: root
        group: bind
        mode: '0644'
        content: |
          options {
              directory "/var/cache/bind";

              listen-on {
                  127.0.0.1;
                  192.168.56.10;
              };

              allow-query {
                  localhost;
                  192.168.56.0/24;
              };

              recursion yes;

              dnssec-validation auto;
          };
      notify: Restart BIND9

    - name: Configure DNS zones
      ansible.builtin.copy:
        dest: /etc/bind/named.conf.local
        owner: root
        group: bind
        mode: '0644'
        content: |
          zone "lab.local" {
              type primary;
              file "/etc/bind/db.lab.local";
          };

          zone "56.168.192.in-addr.arpa" {
              type primary;
              file "/etc/bind/db.192.168.56";
          };
      notify: Restart BIND9

    - name: Create forward DNS zone
      ansible.builtin.copy:
        dest: /etc/bind/db.lab.local
        owner: root
        group: bind
        mode: '0644'
        content: |
          $TTL 86400

          @   IN  SOA dns01.lab.local. admin.lab.local. (
                  2026090301
                  3600
                  1800
                  604800
                  86400
          )

          @           IN  NS      dns01.lab.local.

          dns01       IN  A       192.168.56.10
          client01    IN  A       192.168.56.20
      notify: Restart BIND9

    - name: Create reverse DNS zone
      ansible.builtin.copy:
        dest: /etc/bind/db.192.168.56
        owner: root
        group: bind
        mode: '0644'
        content: |
          $TTL 86400

          @   IN  SOA dns01.lab.local. admin.lab.local. (
                  2026090301
                  3600
                  1800
                  604800
                  86400
          )

          @       IN  NS      dns01.lab.local.

          10      IN  PTR     dns01.lab.local.
          20      IN  PTR     client01.lab.local.
      notify: Restart BIND9

    - name: Validate BIND configuration
      ansible.builtin.command:
        cmd: named-checkconf
      changed_when: false

    - name: Validate forward zone
      ansible.builtin.command:
        cmd: named-checkzone lab.local /etc/bind/db.lab.local
      changed_when: false

    - name: Validate reverse zone
      ansible.builtin.command:
        cmd: named-checkzone 56.168.192.in-addr.arpa /etc/bind/db.192.168.56
      changed_when: false

    - name: Enable and start BIND9
      ansible.builtin.systemd:
        name: bind9
        enabled: true
        state: started
```

---

# 83. Run DNS Automation

From:

```text
~/dns-lab/ansible
```

run:

```bash
ansible-playbook -i inventory.ini dns.yml
```

Ansible performs:

```text
Update package information
        |
        v
Install BIND9
        |
        v
Configure BIND
        |
        v
Create forward zone
        |
        v
Create reverse zone
        |
        v
Validate configuration
        |
        v
Start BIND9
```

---

# 84. Verify BIND Through Ansible

Run:

```bash
ansible dns -i inventory.ini -a "systemctl status bind9 --no-pager"
```

You should see:

```text
Active: active (running)
```

---

# PART M
# AUTOMATE DNS CLIENT

---

# 85. Create client.yml

Create:

```bash
nano client.yml
```

Use:

```yaml
---
- name: Configure DNS Client
  hosts: clients
  become: true

  tasks:

    - name: Install DNS utilities
      ansible.builtin.apt:
        name:
          - dnsutils
        state: present
        update_cache: true

    - name: Configure DNS server
      ansible.builtin.command:
        cmd: resolvectl dns enp0s8 192.168.56.10

    - name: Configure DNS search domain
      ansible.builtin.command:
        cmd: resolvectl domain enp0s8 lab.local

    - name: Display resolver configuration
      ansible.builtin.command:
        cmd: resolvectl status
      register: resolver_status
      changed_when: false

    - name: Show resolver configuration
      ansible.builtin.debug:
        var: resolver_status.stdout
```

Run:

```bash
ansible-playbook -i inventory.ini client.yml
```

---

# 86. Important Note About resolvectl

The above procedure is useful for a laboratory demonstration.

For a persistent configuration that survives network reconfiguration or reboot, configure DNS through the system's network configuration, such as Netplan/systemd-resolved integration, rather than relying only on an ad-hoc `resolvectl` command.

For this training lab, the command demonstrates the DNS relationship clearly:

```text
client01
   |
   | DNS queries
   v
192.168.56.10
   |
   v
BIND9
```

---

# PART N
# COMPLETE AUTOMATED WORKFLOW

---

# 87. Final Automation Architecture

```text
                     Windows 11
                         |
              +----------+----------+
              |                     |
         VirtualBox              WSL2
              |                  Ubuntu
              |                     |
              |              +------+------+
              |              |             |
              |           Vagrant       Ansible
              |                            |
              |                            |
       +------+-------+                    |
       |              |                    |
       v              v                    |
    dns01          client01 <--------------+
       |              |
       |              |
     BIND9          DNS Client
       |
       +---- lab.local
       |
       +---- Reverse DNS
```

---

# 88. Complete Deployment Sequence

The entire lab can be understood as three layers.

## Layer 1: Infrastructure

```text
Windows
   |
VirtualBox
   |
Vagrant
   |
Ubuntu VMs
```

## Layer 2: Configuration

```text
WSL Ubuntu
   |
Ansible
   |
SSH
   |
Ubuntu VMs
```

## Layer 3: Application

```text
dns01
   |
BIND9
   |
DNS zones
   |
DNS records
```

---

# PART O
# VERIFY THE COMPLETE LAB

---

# 89. Check dns01

SSH:

```bash
ssh admin@192.168.56.10
```

Check:

```bash
hostname
```

Expected:

```text
dns01
```

Check IP:

```bash
ip addr
```

Expected:

```text
192.168.56.10
```

Check BIND:

```bash
sudo systemctl status bind9
```

Expected:

```text
active (running)
```

---

# 90. Check DNS Forward Lookup

From client01:

```bash
dig @192.168.56.10 dns01.lab.local
```

Expected:

```text
dns01.lab.local. IN A 192.168.56.10
```

Run:

```bash
dig @192.168.56.10 client01.lab.local
```

Expected:

```text
client01.lab.local. IN A 192.168.56.20
```

---

# 91. Check Reverse Lookup

Run:

```bash
dig @192.168.56.10 -x 192.168.56.10
```

Expected:

```text
dns01.lab.local.
```

Run:

```bash
dig @192.168.56.10 -x 192.168.56.20
```

Expected:

```text
client01.lab.local.
```

---

# 92. Check Using nslookup

Run:

```bash
nslookup dns01.lab.local
```

Then:

```bash
nslookup client01.lab.local
```

Then:

```bash
nslookup 192.168.56.20
```

All three should return correct results.

---

# 93. Test DNS Using ping

Run:

```bash
ping -c 4 dns01.lab.local
```

Expected:

```text
PING dns01.lab.local (192.168.56.10)
```

Then:

```bash
ping -c 4 client01.lab.local
```

Expected:

```text
PING client01.lab.local (192.168.56.20)
```

---

# PART P
# TROUBLESHOOTING

---

# 94. BIND9 Does Not Start

Check:

```bash
sudo systemctl status bind9
```

Check logs:

```bash
sudo journalctl -u bind9
```

Validate:

```bash
sudo named-checkconf
```

Check zones:

```bash
sudo named-checkzone lab.local /etc/bind/db.lab.local
```

and:

```bash
sudo named-checkzone 56.168.192.in-addr.arpa /etc/bind/db.192.168.56
```

---

# 95. DNS Server Cannot Be Reached

From client:

```bash
ping 192.168.56.10
```

If this fails, DNS itself may not be the problem.

Check:

```bash
ip addr
```

on both machines.

Verify:

```text
dns01    192.168.56.10
client01 192.168.56.20
```

Check VirtualBox networking.

Both VMs must be connected to the same Host-only network.

---

# 96. DNS Query Times Out

Run:

```bash
dig @192.168.56.10 client01.lab.local
```

On dns01 check:

```bash
sudo ss -lntup | grep :53
```

DNS should be listening on port 53.

Check firewall:

```bash
sudo ufw status
```

If UFW is enabled, allow DNS:

```bash
sudo ufw allow 53/tcp
sudo ufw allow 53/udp
```

---

# 97. DNS Record Not Found

Check the zone:

```bash
sudo named-checkzone lab.local /etc/bind/db.lab.local
```

Check serial number.

After changing a zone:

```text
2026090301
```

change it to something higher, for example:

```text
2026090302
```

Then reload:

```bash
sudo systemctl reload bind9
```

---

# 98. Ansible Cannot Connect

Test:

```bash
ssh admin@192.168.56.10
```

If SSH fails, Ansible will also fail.

Test:

```bash
ansible all -i inventory.ini -m ping
```

Check inventory:

```bash
cat inventory.ini
```

---

# 99. Ansible Permission Error

If Ansible reports permission problems, use:

```bash
ansible-playbook -i inventory.ini dns.yml --ask-become-pass
```

This asks for the sudo password.

---

# 100. Vagrant VM Does Not Start

Run:

```powershell
vagrant status
```

Then:

```powershell
vagrant up
```

Check VirtualBox directly:

```powershell
VBoxManage list runningvms
```

Also verify that the selected Vagrant box is available and compatible with the installed Vagrant/VirtualBox versions.

---

# PART Q
# MANUAL VS AUTOMATED IMPLEMENTATION

---

# 101. Manual Method

```text
Create VM manually
       |
Configure network manually
       |
Install Ubuntu
       |
Install BIND9
       |
Edit configuration files
       |
Create zone files
       |
Validate
       |
Restart BIND
       |
Configure client
       |
Test DNS
```

Advantages:

- Understand every configuration
- Good for learning
- Easy to inspect individual steps

Disadvantages:

- Time consuming
- Error prone
- Difficult to repeat consistently

---

# 102. Automated Method

```text
Vagrantfile
     |
     v
Create VMs
     |
     v
Ansible
     |
     +---- Install BIND9
     |
     +---- Configure BIND
     |
     +---- Create zones
     |
     +---- Validate
     |
     +---- Configure client
     |
     v
Working DNS Lab
```

Advantages:

- Repeatable
- Faster
- Consistent
- Easy to rebuild
- Suitable for infrastructure training
- Provides practical automation experience

---

# PART R
# PROJECT DIRECTORY

---

# 103. Recommended Final Directory Structure

Windows:

```text
D:\dns-lab\
│
├── Vagrantfile
│
└── ansible\
    ├── inventory.ini
    ├── dns.yml
    └── client.yml
```

WSL:

```text
~/dns-lab/
└── ansible/
    ├── inventory.ini
    ├── dns.yml
    └── client.yml
```

---

# 104. Important Commands Summary

## Windows

```powershell
wsl --status
wsl -l -v
vagrant --version
vagrant up
vagrant status
vagrant ssh dns01
vagrant ssh client01
vagrant halt
vagrant destroy
VBoxManage --version
```

---

## WSL Ubuntu

```bash
sudo apt update
sudo apt upgrade -y
ansible --version
ssh -V
ansible all -i inventory.ini -m ping
ansible-playbook -i inventory.ini dns.yml
ansible-playbook -i inventory.ini client.yml
```

---

## Ubuntu DNS Server

```bash
hostname
ip addr
sudo apt install bind9 bind9utils dnsutils -y
sudo systemctl status bind9
sudo systemctl restart bind9
sudo systemctl reload bind9
sudo named-checkconf
sudo named-checkzone lab.local /etc/bind/db.lab.local
sudo named-checkzone 56.168.192.in-addr.arpa /etc/bind/db.192.168.56
```

---

## DNS Testing

```bash
dig @192.168.56.10 dns01.lab.local
dig @192.168.56.10 client01.lab.local
dig @192.168.56.10 -x 192.168.56.20
nslookup dns01.lab.local
nslookup client01.lab.local
nslookup 192.168.56.20
```

---

# PART S
# PRACTICAL EXERCISES

---

# Exercise 1: Add Another Host

Add:

```text
web01.lab.local
```

IP:

```text
192.168.56.30
```

Add:

```text
web01 IN A 192.168.56.30
```

Add reverse record:

```text
30 IN PTR web01.lab.local.
```

Test:

```bash
dig @192.168.56.10 web01.lab.local
```

and:

```bash
dig @192.168.56.10 -x 192.168.56.30
```

---

# Exercise 2: Add a CNAME

Create:

```text
www.lab.local
```

as an alias for:

```text
client01.lab.local
```

Record:

```text
www IN CNAME client01.lab.local.
```

Test:

```bash
dig @192.168.56.10 www.lab.local
```

---

# Exercise 3: Add an MX Record

Create:

```text
mail.lab.local
```

IP:

```text
192.168.56.40
```

Add:

```text
mail IN A 192.168.56.40
```

Then:

```text
@ IN MX 10 mail.lab.local.
```

Test:

```bash
dig @192.168.56.10 lab.local MX
```

---

# Exercise 4: Add a Second DNS Server

Create:

```text
dns02
```

IP:

```text
192.168.56.30
```

Configure it as a secondary server.

Architecture:

```text
dns01
Primary
192.168.56.10
      |
      | AXFR / IXFR
      v
dns02
Secondary
192.168.56.30
```

BIND's primary/secondary architecture uses zone transfers to replicate zone data.

---

# Exercise 5: Configure DNS Forwarding

Configure dns01 to forward external queries to an upstream DNS resolver.

Concept:

```text
client01
   |
   v
dns01
   |
   | external domain
   v
upstream DNS
```

BIND supports both global and per-domain forwarding.

---

# Exercise 6: Test DNS Failure

Stop BIND:

```bash
sudo systemctl stop bind9
```

From client01:

```bash
dig @192.168.56.10 client01.lab.local
```

Observe the failure.

Start BIND again:

```bash
sudo systemctl start bind9
```

Test again.

---

# Exercise 7: Automate Adding a DNS Record

Modify:

```text
dns.yml
```

to add:

```text
web01
```

Then run:

```bash
ansible-playbook -i inventory.ini dns.yml
```

Verify:

```bash
dig @192.168.56.10 web01.lab.local
```

---

# PART T
# NEXT LEVEL DNS LABS

After completing the basic DNS lab, the following topics can be added.

## Level 1

```text
Forward DNS
Reverse DNS
A records
AAAA records
CNAME
PTR
NS
SOA
MX
TXT
```

## Level 2

```text
Primary DNS
Secondary DNS
AXFR
IXFR
DNS NOTIFY
Zone transfers
```

## Level 3

```text
DNS forwarding
Caching
Recursive DNS
Conditional forwarding
```

## Level 4

```text
DNSSEC
TSIG
Dynamic DNS
Secure zone transfers
```

## Level 5

```text
DNS views
Split DNS
Internal/external DNS
DNS load distribution
High availability
```

## Level 6

```text
Ansible roles
Jinja2 templates
Ansible Vault
Dynamic inventories
CI/CD DNS configuration
Automated DNS testing
```

---

# 105. Final Lab Result

The completed environment should look like:

```text
                         WINDOWS 11
                              |
              +---------------+---------------+
              |                               |
              |                         WSL2 Ubuntu
              |                               |
              |                     +---------+---------+
              |                     |                   |
              |                  Vagrant             Ansible
              |                     |                   |
              |                     |                   |
              +---------------------+-------------------+
                                    |
                             Oracle VirtualBox
                                    |
                       192.168.56.0/24 Network
                                    |
                     +--------------+--------------+
                     |                             |
                     |                             |
                     v                             v
                  dns01                        client01
             192.168.56.10                  192.168.56.20
                     |                             |
                     |                             |
                   BIND9                       DNS Client
                     |
             +-------+-------+
             |               |
             v               v
        lab.local       Reverse Zone
             |               |
             |               |
      +------+-------+       |
      |              |       |
      v              v       v
   dns01          client01   PTR
192.168.56.10   192.168.56.20
```

The key workflow is:

```text
MANUAL LEARNING
      |
      v
Understand Ubuntu networking
      |
      v
Understand BIND9
      |
      v
Understand DNS zones
      |
      v
Understand DNS records
      |
      v
Understand DNS testing
      |
      v
AUTOMATION
      |
      v
Vagrant
      |
      v
Create VMs
      |
      v
Ansible
      |
      v
Configure BIND9
      |
      v
Configure DNS client
      |
      v
Test automatically
```

# 106. Official Documentation

BIND 9 Administrator Reference Manual: [BIND 9 documentation](https://bind9.readthedocs.io/en/latest/?utm_source=chatgpt.com)

BIND zone configuration and primary/secondary documentation: [BIND 9 zone configuration](https://bind9.readthedocs.io/en/stable/chapter3.html?utm_source=chatgpt.com)

BIND forwarding documentation: [BIND 9 forwarding configuration](https://bind9.readthedocs.io/en/stable/reference.html?utm_source=chatgpt.com)

Ansible installation and control-node requirements: [Ansible installation documentation](https://docs.ansible.com/projects/ansible-core/devel/installation_guide/intro_installation.html?utm_source=chatgpt.com)

Ansible and Windows/WSL: [Ansible Windows control-node documentation](https://docs.ansible.com/projects/ansible/latest/os_guide/intro_windows.html?utm_source=chatgpt.com)

Vagrant VirtualBox provider: [Vagrant VirtualBox provider documentation](https://developer.hashicorp.com/vagrant/docs/providers/virtualbox?utm_source=chatgpt.com)

---

# 107. Recommended Training Sequence

For a practical Linux/DNS administration course, perform the lab in this order:

```text
DAY 1
Windows + WSL2
        |
Ubuntu WSL
        |
VirtualBox
        |
Manual VM creation
        |
Ubuntu networking
```

```text
DAY 2
BIND9
 |
DNS concepts
 |
Forward zone
 |
Reverse zone
 |
DNS records
 |
dig / nslookup
```

```text
DAY 3
Vagrant
 |
Vagrantfile
 |
Automated VM creation
 |
VirtualBox integration
```

```text
DAY 4
Ansible
 |
Inventory
 |
SSH
 |
Ansible ping
 |
Playbooks
 |
BIND9 automation
```

```text
DAY 5
Primary/Secondary DNS
 |
Zone transfer
 |
AXFR / IXFR
 |
Forwarding
 |
Caching
 |
DNS troubleshooting
```

This progression allows the administrator to understand **what is being automated before automating it**.