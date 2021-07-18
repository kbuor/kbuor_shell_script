#!/bin/bash
clear
echo '==========================================='
echo 'Cassandra Server deployment script by Kbuor'
echo '==========================================='
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
	read -p 'Please enter your Cassandra node 01 ip address (ex: 172.11.11.21): ' var_ip1
	read -p 'Please enter your Cassandra node 02 ip address (ex: 172.11.11.22): ' var_ip2
	read -p 'Please enter your Cassandra node 03 ip address (ex: 172.11.11.23): ' var_ip3
	read -p 'Please enter your Cassandra node 04 ip address (ex: 172.11.11.24): ' var_ip4
	read -p 'Please enter your network (ex: 172.11.11.0/24): ' var_nw
	read -p 'What is this node number? (ex: 1): ' var_node
	read -p 'Please enter this Cassandra server hostname (ex: cassandra01.kbuor.local): ' var_hostname
	echo
	echo 'Your informations are: '
	echo "You are deploying node: $var_node"
	echo "Cassandra node 01 ip address: $var_ip1"
	echo "Cassandra node 02 ip address: $var_ip2"
	echo "Cassandra node 03 ip address: $var_ip3"
	echo "Cassandra node 04 ip address: $var_ip4"
	echo "Network: $var_nw"
	echo "Cassandra node $var_node hostname: $var_hostname"
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
yum install -y java
cat << 'EOF' > /etc/yum.repos.d/cassandra.repo
[cassandra]
name=Apache Cassandra
baseurl=https://www.apache.org/dist/cassandra/redhat/311x/
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://www.apache.org/dist/cassandra/KEYS
EOF
yum install -y cassandra cassandra-tools
sed -i 10s/"cluster_name: 'Test Cluster'"/"cluster_name: 'vCD Performance Metrics Database'"/g /etc/cassandra/default.conf/cassandra.yaml
sed -i 103s/"authenticator: AllowAllAuthenticator"/"authenticator: PasswordAuthenticator"/g /etc/cassandra/default.conf/cassandra.yaml
sed -i 112s/"authorizer: AllowAllAuthorizer"/"authorizer: CassandraAuthorizer"/g /etc/cassandra/default.conf/cassandra.yaml
sed -i 425s/"- seeds: \"127.0.0.1\""/"- seeds: \"$var_ip1,$var_ip2\""/g /etc/cassandra/default.conf/cassandra.yaml
if [ $var_node -eq 1 ]
then
	sed -i 612s/"listen_address: localhost"/"listen_address: $var_ip1"/g /etc/cassandra/default.conf/cassandra.yaml
	sed -i 689s/"rpc_address: localhost"/"rpc_address: $var_ip1"/g /etc/cassandra/default.conf/cassandra.yaml
fi
if [ $var_node -eq 2 ]
then
	sed -i 612s/"listen_address: localhost"/"listen_address: $var_ip2"/g /etc/cassandra/default.conf/cassandra.yaml
	sed -i 689s/"rpc_address: localhost"/"rpc_address: $var_ip2"/g /etc/cassandra/default.conf/cassandra.yaml
fi
if [ $var_node -eq 3 ]
then
	sed -i 612s/"listen_address: localhost"/"listen_address: $var_ip3"/g /etc/cassandra/default.conf/cassandra.yaml
	sed -i 689s/"rpc_address: localhost"/"rpc_address: $var_ip3"/g /etc/cassandra/default.conf/cassandra.yaml
fi
if [ $var_node -eq 4 ]
then
	sed -i 612s/"listen_address: localhost"/"listen_address: $var_ip4"/g /etc/cassandra/default.conf/cassandra.yaml
	sed -i 689s/"rpc_address: localhost"/"rpc_address: $var_ip4"/g /etc/cassandra/default.conf/cassandra.yaml
fi
service cassandra start
chkconfig cassandra on
#
# Finish deployment
#
clear
echo '==========================================='
echo 'Cassandra Server deployment script by Kbuor'
echo '==========================================='
echo
echo 'Cassandra Server has been deployed successfully'
echo
