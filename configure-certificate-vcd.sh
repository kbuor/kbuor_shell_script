#!/bin/bash
# Author: Trung Nguyen Kbuor
clear
echo '========================================='
echo 'Configure Certificate for vCloud Director'
echo '========================================='
echo
echo 'This script should be run on ALL vcd-cell'
echo
# Select type of certificate file
var_skippass=0
echo 'What is type of your certificate file?'
echo
echo '1. Normal certificate (include: certificate, CA, private key).'
echo '2. certificates.ks file'
echo
read -p 'Your choice: ' var_select
while [ \( $var_select -ne 1 \) -a \( $var_select -ne 2 \) ]
do
	read -p 'Your choice: ' var_select
done
# Create certificates.ks file
if [ $var_select -eq 1 ]
then
#	Check existing files
	var_check=1
	while [ $var_check -eq 1 ]
	do
		echo
		echo 'Please rename three certificate files to: certificate.crt (for certificate), cert-ca.crt (for chain), private.key (for private key) and put them to /tmp'
		echo 'Checking existing file...'
		echo
		if [ -e /tmp/certificate.crt ]
		then
			echo '/tmp/certificate.crt: OK'
		else
			echo '/tmp/certificate.crt: NOT FOUND'
		fi
		if [ -e /tmp/cert-ca.crt ]
		then
			echo '/tmp/cert-ca.crt: OK'
		else
			echo '/tmp/cert-ca.crt: NOT FOUND'
		fi
		if [ -e /tmp/private.key ]
		then
			echo '/tmp/private.key: OK'
		else
			echo '/tmp/private.key: NOT FOUND'
		fi
		if [ \( -e /tmp/certificate.crt \) -a \( -e /tmp/cert-ca.crt \) -a \( -e /tmp/private.key \) ]
		then
			var_check=0
		fi
		echo
		read -p "Press enter key to continue"
	done
#	Create certificates.ks file
	openssl pkcs12 -export -out /tmp/certificate.pfx -inkey /tmp/private.key -in /tmp/certificate.crt -password pass:password
	/opt/vmware/vcloud-director/jre/bin/keytool -keystore /tmp/certificates.ks -storepass password -keypass password -storetype JCEKS -importkeystore -srckeystore /tmp/certificate.pfx -srcstorepass password
	/opt/vmware/vcloud-director/jre/bin/keytool -keystore /tmp/certificates.ks -storetype JCEKS -changealias -alias 1 -destalias http -storepass password
	/opt/vmware/vcloud-director/jre/bin/keytool -keystore /tmp/certificates.ks -storepass password -keypass password -storetype JCEKS -importkeystore -srckeystore /tmp/certificate.pfx -srcstorepass password
	/opt/vmware/vcloud-director/jre/bin/keytool -keystore /tmp/certificates.ks -storetype JCEKS -changealias -alias 1 -destalias consoleproxy -storepass password
	/opt/vmware/vcloud-director/jre/bin/keytool -importcert -alias root -file /tmp/cert-ca.crt -storetype JCEKS -keystore /tmp/certificates.ks -storepass password << EOF
y
EOF
	/opt/vmware/vcloud-director/jre/bin/keytool  -list -keystore /tmp/certificates.ks -storetype JCEKS -storepass password
	var_select=2
	echo
	echo 'Your certificates.ks file password is: password'
	echo 'Please take note for continue the configuration'
	read -p 'Press Enter to continue'
fi
# Configure certificates.ks to vcloud director
if [ $var_select -eq 2 ]
then
	var_check=1
	while [ $var_check -eq 1 ]
	do
		echo
		echo 'Please put the certificates.ks file to /tmp directory'
		echo 'Checking existing file...'
		echo
		if [ -e /tmp/certificates.ks ]
		then
			echo '/tmp/certificates.ks: OK'
			var_check=0
		else
			echo '/tmp/certificates.ks: NOT FOUND'
		fi
		echo
		read -p "Press enter key to continue"
	done
	service vmware-vcd stop
	mv /opt/vmware/vcloud-director/certificates.ks /opt/vmware/vcloud-director/certificates.ks.old
	cp /tmp/certificates.ks /opt/vmware/vcloud-director/
	chmod -R 777 /opt/vmware/vcloud-director/certificates.ks
	/opt/vmware/vcloud-director/jre/bin/keytool  -list -keystore /opt/vmware/vcloud-director/certificates.ks -storetype JCEKS -storepass $var_certpass
	/opt/vmware/vcloud-director/bin/configure
fi
#clear
echo '========================================='
echo 'Configure Certificate for vCloud Director'
echo '========================================='
echo
echo 'vCloud Director Certificate has been configured successfully'
echo
