#!/bin/bash
# Author: Trung Nguyen Kbuor
clear
echo '============================='
echo 'AMQP Server deployment script'
echo '============================='
echo
echo 'Please make sure you have updated system, disabled SELINUX and tempolory disabled firewall before running this script'
echo '!!!WARNING!!! Please make sure you have created DNS record for all AMQP node.'
echo 'If you do not have DNS Server, please add AMQP hostname of all node to host file in each node.'
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
	read -p 'Please enter your amqp server ip address (ex: 172.11.11.251): ' var_ip
	read -p 'Please enter your network (ex: 172.11.11.0/24): ' var_nw
	read -p 'Please enter your amqp server hostname (ex: amqp01.kbuor.local): ' var_hostname
	echo
	echo 'Your informations are: '
	echo "IP Address: $var_ip"
	echo "Network: $var_nw"
	echo "AMQP Server hostname: $var_hostname"
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
wget http://packages.erlang-solutions.com/erlang-solutions-1.0-1.noarch.rpm
sudo rpm -Uvh erlang-solutions-1.0-1.noarch.rpm
sudo yum install -y erlang
wget https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.8.17/rabbitmq-server-3.8.17-1.el8.noarch.rpm
sudo rpm --import https://www.rabbitmq.com/rabbitmq-signing-key-public.asc
sudo yum install -y rabbitmq-server-3.8.17-1.el8.noarch.rpm
chkconfig rabbitmq-server on
systemctl start rabbitmq-server
systemctl enable --now rabbitmq-server
rabbitmq-plugins enable rabbitmq_management
chown -R rabbitmq:rabbitmq /var/lib/rabbitmq/
systemctl restart rabbitmq-server
rabbitmqctl add_user vcloud p@ssW0rd
rabbitmqctl set_user_tags vcloud administrator
rabbitmqctl set_permissions -p / vcloud ".*" ".*" ".*"
#
# Finish deployment
#
clear
echo '============================='
echo 'AMQP Server deployment script'
echo '============================='
echo
echo 'AMQP Server has been deployed successfully'
echo
echo 'Select running enviroment: '
echo '1. Standalone'
echo '2. Clustering - Create new cluster'
echo '3. Clustering - Join existing cluster'
read -p 'Your choice: ' var_env
while [ \( $var_env -ne 1 \) -a  \( $var_env -ne 2 \) -a \( $var_env -ne 3 \) ]
do
	read -p 'Your choice: ' var_env
done
if [ $var_env -eq 1 ]
then
	echo 'AMQP Standalone applied'
	echo
fi
if [ $var_env -eq 2 ]
then
	echo 'AMQP new cluster created'
	echo 'Please take note the information below to use for joining other AMQP node to this cluster'
	echo
	var_name=`hostname | awk -F . '{print $1}'`
	printf "1. Custer name: "
	echo "rabbit@$var_name"
	printf "2. Custer cookie: "
	echo `cat /var/lib/rabbitmq/.erlang.cookie`
	echo
fi
if [ $var_env -eq 3 ]
then
	echo 'Joining to existing cluster'
	echo
	read -p '1. Enter cluster name: ' var_join_name
	read -p '2. Enter cluster cookie: ' var_join_cookie
	systemctl stop rabbitmq-server
	echo $var_join_cookie > /var/lib/rabbitmq/.erlang.cookie
	systemctl start rabbitmq-server && systemctl enable --now rabbitmq-server
	rabbitmqctl stop_app
	rabbitmqctl reset
	rabbitmqctl join_cluster $var_join_name
	rabbitmqctl start_app
	rabbitmqctl set_policy ha-all "" '{"ha-mode":"all","ha-sync-mode":"automatic"}'
	echo
	echo 'Cluster joined!'
fi
