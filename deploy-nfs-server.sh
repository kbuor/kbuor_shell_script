#!/bin/bash
clear
echo '====================================='
echo 'NFS Server deployment script by Kbuor'
echo '====================================='
echo
echo 'Please make sure you have updated system, disabled SELINUX and tempolory disabled firewall before running this script'
#
# Check SELINUX status
#
grep -q SELINUX=disabled /etc/sysconfig/selinux
var_tmp1=$?
grep -q SELINUX=disabled /etc/selinux/config
var_tmp2=$?
while [ \( $var_tmp1 -ne 0 \) -o \( $var_tmp2 -ne 0 \) ]
do
	echo 'You have not disabled SELINUX. Please disable SELINUX before continuing.'
	read -p 'Do you want to disable SELINUX? (Yes/No): ' var_tmp3
	while [ \( $var_tmp3 != "y" \) -a \( $var_tmp3 != "Yes" \) -a \( $var_tmp3 != "yes" \) -a \( $var_tmp3 != "n" \) -a \( $var_tmp3 != "No" \) -a \( $var_tmp3 != "no" \) ]
	do
		read -p 'Do you want to disable SELINUX? (Yes/No): ' var_tmp3
	done
	if [ \( $var_tmp3 == "y" \) -o \( $var_tmp3 == "Yes" \) -o \( $var_tmp3 == "yes" \) ]
	then
		sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/sysconfig/selinux
		sed -i s/^SELINUX=.*$/SELINUX=disabled/ /etc/selinux/config
		sudo reboot
	fi
	grep -q SELINUX=disabled /etc/sysconfig/selinux
	var_tmp1=$?
	grep -q SELINUX=disabled /etc/selinux/config
	var_tmp2=$?
done
echo 'Your SELINUX has been disabled.'
#
# Collecting informations for deployment
#
var_loop1=1
while [ $var_loop1 -eq 1 ]
do
	echo 'Please enter some basic information to deploy.'
	read -p 'Please enter your NFS server ip address (ex: 172.11.11.251): ' var_ip
	read -p 'Please enter your network (ex: 172.11.11.0/24): ' var_nw
	read -p 'Please enter your NFS server hostname (ex: nfs01.kbuor.local): ' var_hostname
	read -p 'Please enter your disk to create NFS storage (ex: /dev/sdb): ' var_disk
	echo
	echo 'Your informations are: '
	echo "IP Address: $var_ip"
	echo "Network: $var_nw"
	echo "NFS Server hostname: $var_hostname"
	echo "NFS Storage: $var_disk"
	echo
	read -p 'Please check the information again. Do you want to change it? (Yes/No): ' var_info
	while [ \( $var_info != "y" \) -a \( $var_info != "Yes" \) -a \( $var_info != "yes" \) -a \( $var_info != "n" \) -a \( $var_info != "No" \) -a \( $var_info != "no" \) ]
	do
		read -p 'Please check the information again. Do you want to change it? (Yes/No): ' var_info
	done
	if [ \( $var_info == "y" \) -o \( $var_info == "Yes" \) -o \( $var_info == "yes" \) ]
	then
		var_loop1=1
	else
		var_loop1=0
	fi
done
#
# Start deloyment
#
hostnamectl set-hostname $var_hostname
systemctl stop firewalld && systemctl disable --now firewalld
yum install -y open-vm-tools epel-release wget unzip git
yum update -y
fdisk $var_disk << EOF
n
p



t
8e
w
EOF
var_disk1="$var_disk"1
pvcreate $var_disk1
vgcreate vg_nfsshare_vcloud_director $var_disk1
lvcreate -n vol_nfsshare_vcloud_director -l 100%FREE vg_nfsshare_vcloud_director
mkfs.ext4 /dev/vg_nfsshare_vcloud_director/vol_nfsshare_vcloud_director
mkdir -p /nfsshare/vcloud_director
temp1=`blkid /dev/vg_nfsshare_vcloud_director/vol_nfsshare_vcloud_director | awk -F \  '{print $2}'`
uuid=`cat $temp1 | awk -F \" '{print $2}'`
echo "UUID=$uuid /nfsshare/vcloud_director ext4 defaults 0 0" >> /etc/fstab
mount -a
chmod 750 /nfsshare/vcloud_director
chown root:root /nfsshare/vcloud_director
yum install -y nfs-utils
systemctl enable --now nfs-server rpcbind
systemctl start nfs-server rpcbind
echo "/nfsshare/vcloud_director "$var_nw"(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
exportfs -a
exportfs -v
#
# Finish deployment
#
clear
echo '====================================='
echo 'NFS Server deployment script by Kbuor'
echo '====================================='
echo
echo 'NFS Server has been deployed successfully'
echo
echo 'Your NFS directory: /nfsshare/vcloud_director'
echo "Your NFS mount point: "$var_ip":/nfsshare/vcloud_director"
echo
