#!/bin/bash
clear
echo '====================================='
echo 'DNS Server deployment script by Kbuor'
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
	read -p 'Please enter your dns server ip address (ex: 172.11.11.251): ' var_ip
	read -p 'Please enter your network (ex: 172.11.11.0/24): ' var_nw
	var_network=`echo $var_nw | awk -F / '{print $1}'`
	var_subnet=`echo $var_nw | awk -F / '{print $2}'`
	read -p 'Please enter your domain name (ex: kbuor.local): ' var_domain
	read -p 'Please enter your dns server hostname (ex: dns01.kbuor.local): ' var_hostname
	echo
	echo 'Your informations are: '
	echo "IP Address: $var_ip"
	echo "Network: $var_nw"
	echo "Domain: $var_domain"
	echo "DNS Server hostname: $var_hostname"
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
yum install -y open-vm-tools epel-release wget unzip bind bind-utils
yum update -y
systemctl stop firewalld && systemctl disable --now firewalld
hostnamectl set-hostname $var_hostname
#
# Edit DNS Server config
#
sed -i s/"listen-on port 53 { 127.0.0.1; };"/"listen-on port 53 { 127.0.0.1; $var_ip; };"/ /etc/named.conf
sed -i s/"allow-query     { localhost; };"/"allow-query     { localhost; $var_network\/$var_subnet; };"/ /etc/named.conf
#
# Add forward zone
#
sed -i "59 i zone \"$var_domain\" IN {" /etc/named.conf
sed -i "60 i type master;" /etc/named.conf
sed -i "61 i file \"forward.$var_domain\";" /etc/named.conf
sed -i "62 i allow-update { none; };" /etc/named.conf
sed -i "63 i };" /etc/named.conf
#
# Add reverse zone
#
var_ptr=`echo $var_network | awk -F . '{print $3"."$2"."$1}'`
sed -i "64 i zone \"$var_ptr.in-addr.arpa\" IN {" /etc/named.conf
sed -i "65 i type master;" /etc/named.conf
sed -i "66 i file \"reverse.$var_domain\";" /etc/named.conf
sed -i "67 i allow-update { none; };" /etc/named.conf
sed -i "68 i };" /etc/named.conf
#
# Create forward file
#
var_record=`echo $var_hostname | awk -F . '{print $1}'`
touch /var/named/forward.$var_domain
cat << EOF > /var/named/forward.$var_domain
\$TTL 86400
@ IN SOA $var_hostname. root.$var_domain. (
2011071001 ;Serial
3600 ;Refresh
1800 ;Retry
604800 ;Expire
86400 ;Minimun TTL
)
@ IN NS $var_hostname.
@ IN A $var_ip
$var_record IN A $var_ip
EOF
#
# Create reverse file
#
var_ptr_record=`echo $var_ip | awk -F . '{print $4}'`
touch /var/named/reverse.$var_domain
cat << EOF > /var/named/reverse.$var_domain
\$TTL 86400
@ IN SOA $var_hostname. root.$var_domain. (
2011071001 ;Serial
3600 ;Refresh
1800 ;Retry
604800 ;Expire
86400 ;Minimun TTL
)
@ IN NS $var_hostname.
$var_record IN A $var_ip
$var_ptr_record IN PTR $var_hostname.
EOF
#
# Start DNS Service
#
systemctl start named
systemctl enable --now named
chgrp named -R /var/named
chown -v root:named /etc/named.conf
restorecon -rv /var/named
restorecon /etc/named.conf
#
# Finish deployment
#
clear
echo '====================================='
echo 'DNS Server deployment script by Kbuor'
echo '====================================='
echo
echo 'DNS Server has been deployed successfully'
echo
named-checkzone $var_domain /var/named/forward.$var_domain
named-checkzone $var_domain /var/named/reverse.$var_domain
