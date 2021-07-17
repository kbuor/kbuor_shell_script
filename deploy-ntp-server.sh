#!/bin/bash
clear
echo '====================================='
echo 'NTP Server deployment script by Kbuor'
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
	read -p 'Please enter your ntp server ip address (ex: 172.11.11.251): ' var_ip
	read -p 'Please enter your network (ex: 172.11.11.0): ' var_network
	read -p 'Please enter your subnet mask (ex: 255.255.255.0): ' var_subnet
	read -p 'Please enter your ntp server hostname (ex: ntp01.kbuor.local): ' var_hostname
	echo
	echo 'Your informations are: '
	echo "IP Address: $var_ip"
	echo "Network: $var_network mask $var_subnet"
	echo "NTP Server hostname: $var_hostname"
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
yum install -y open-vm-tools epel-release wget git unzip ntp
yum update -y
sed -i '21d' /etc/ntp.conf
sed -i '21d' /etc/ntp.conf
sed -i '21d' /etc/ntp.conf
sed -i '21d' /etc/ntp.conf
sed -i "18 i restrict $var_network mask $var_subnet nomodify notrap" /etc/ntp.conf
sed -i "22 i server 1.vn.pool.ntp.org iburst" /etc/ntp.conf
systemctl start ntpd && systemctl enable --now ntpd
#
# Finish deployment
#
clear
echo '====================================='
echo 'NTP Server deployment script by Kbuor'
echo '====================================='
echo
echo 'NTP Server has been deployed successfully'
echo
ntpq -p
echo
