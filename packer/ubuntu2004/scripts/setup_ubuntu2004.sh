#!/bin/bash -eux
apt-get update
apt-get upgrade -y

# Add system user to sudoers.
echo "system        ALL=(ALL)       NOPASSWD:ALL" >> /etc/sudoers
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

apt install neofetch -y

apt-get install -y python3-pip nfs-common

sudo adduser --disabled-password --gecos "" vcokltfre
sudo usermod -aG sudo vcokltfre

mkdir /home/vcokltfre/.ssh
curl -o /home/vcokltfre/.ssh/authorized_keys https://github.com/vcokltfre.keys

# Set up for hashicorp packages
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

# Install VMWare Guestinfo Cloud-init source
curl -sSL https://raw.githubusercontent.com/vmware/cloud-init-vmware-guestinfo/master/install.sh | sh -

# Ensure cloud-init can configure network
rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg
rm -f /etc/cloud/cloud.cfg.d/50-curtin-networking.cfg
rm -f /etc/cloud/cloud.cfg.d/99-installer.cfg

# Make sure all datasources are loaded, as rancher uses the NoCloud config
rm -f /etc/cloud/cloud.cfg.d/99-DataSourceVMwareGuestInfo.cfg
echo "datasource_list: ['NoCloud', 'ConfigDrive', 'VMwareGuestInfo']" > /etc/cloud/cloud.cfg.d/90_dpkg.cfg

# Reset Cloud-init state (https://stackoverflow.com/questions/57564641/openstack-packer-cloud-init)
systemctl stop cloud-init
rm -rf /var/lib/cloud/
# cloud-init clean -s -l

# Reset Machine-ID
# http://manpages.ubuntu.com/manpages/bionic/man5/machine-id.5.html
# This is the equivalent of the SID in Windows
# Netplan also uses this as DHCP Identifier, causing multiple VMs from the same Image
# to get the same IP Address
# This file shouldn't not be deleted but only truncated,
# see https://bugs.launchpad.net/ubuntu/+source/systemd/+bug/1508766
# see https://github.com/DanHam/packer-virt-sysprep/blob/master/sysprep-op-machine-id.sh
# Machine ID file locations
sysd_id="/etc/machine-id"
dbus_id="/var/lib/dbus/machine-id"

# Remove and recreate (and so empty) the machine-id file under /etc
if [ -e ${sysd_id} ]; then
    rm -f ${sysd_id} && touch ${sysd_id}
fi

# Remove the machine-id file under /var/lib/dbus if it is not a symlink
if [[ -e ${dbus_id} && ! -h ${dbus_id} ]]; then
    rm -f ${dbus_id}
fi

# Fix console-setup early
ln -s /usr/share/X11/xkb/symbols/us /usr/share/X11/xkb/symbols/en