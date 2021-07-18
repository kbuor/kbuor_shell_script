#!/bin/bash
clear
echo '============================================================'
echo 'Configure Cassandra integrated with vCloud Director by Kbuor'
echo '============================================================'
echo
echo 'Please run this command bellow to ALL vcd-cell and restart vmware-vcd service before run this script.'
echo
echo 'echo "cassandra.use.ssl = 0" >> /opt/vmware/vcloud-director/etc/global.properties'
echo 'systemctl restart vmware-vcd'
echo
echo 'This script should be run in ONLY ONE vcd-cell'
echo
var_loop0=1
while [ $var_loop0 -eq 1 ]
do
	read -p 'Do you want to continue? (Yes/No): ' var_check
	while [ \( $var_check != "y" \) -a \( $var_check != "Yes" \) -a \( $var_check != "yes" \) -a \( $var_check != "n" \) -a \( $var_check != "No" \) -a \( $var_check != "no" \) ]
	do
		read -p 'Do you want to continue? (Yes/No): ' var_info
	done
	if [ \( $var_check == "y" \) -o \( $var_check == "Yes" \) -o \( $var_check == "yes" \) ]
	then
		var_loop0=0
	else
		var_loop0=1
	fi
done
#
# Collecting informations for deployment
#
var_loop1=1
while [ $var_loop1 -eq 1 ]
do
	echo 'Please enter some basic information to deploy.'
	read -p 'Please enter your all Cassandra node ip address (ex: 172.11.11.21,172.11.11.22,172.11.11.23...): ' var_ip
	echo
	echo 'Your informations are: '
	echo "Cassandra all node ip address: $var_ip"
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
cd /opt/vmware/vcloud-director/bin
./cell-management-tool cassandra --configure --create-schema --cluster-nodes $var_ip --username cassandra --password 'cassandra' --ttl 30 --port 9042
#
# Finish deployment
#
clear
echo '============================================================'
echo 'Configure Cassandra integrated with vCloud Director by Kbuor'
echo '============================================================'
echo
echo 'Cassandra has been configured successfully with vCloud Director'
echo 'Please restart vcloud director service on ALL vcd-cell'
echo
