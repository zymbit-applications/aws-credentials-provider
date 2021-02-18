#!/usr/bin/env bash

#PREREQUISITES
#1. Make certificate from zymkey manually
#openssl req -key nonzymkey.key -new -out zymkey.csr -engine zymkey_ssl -keyform e 
#Country Name (2 letter code) [AU]:
#State or Province Name (full name) [Some-State]:
#Locality Name (eg, city) []:<REGION>
#Organization Name (eg, company) [Internet Widgits Pty Ltd]:<CREDENTIAL URL> (cxxxxxxxxxxxxx)
#Organizational Unit Name (eg, section) []:<ROLE ALIAS>
#Common Name (e.g. server FQDN or YOUR name) []:<THING NAME>
#Email Address []:

#2. Sign csr with private CA
#3. Put device.crt into /opt/zymbit/device.crt
#4. Put root.ca.pem into /opt/zymbit/root.ca.pem





#INITAIL CHECKS
#Check AWS CLI version is acceptable
#aws --version

#Ensure device cert is in /opt/zymbit/device.crt
[ ! -f /opt/zymbit/device.crt] && echo "/opt/zymbit/device.crt does not exist. Exiting." && exit 1

#Ensure root CA pem file is in /opt/zymbit/root.ca.pem
[ ! -f /opt/zymbit/root.ca.pem] && echo "/opt/zymbit/root.ca.pem does not exist. Exiting." && exit 1






#GET DEVICE INFO
THING_NAME=$(openssl x509 -in zymkey.crt -noout -subject -nameopt RFC2253 | awk -F , '{print $1}' | awk -F = '{print $3}')

ROLE_ALIAS=$(openssl x509 -in zymkey.crt -noout -subject -nameopt RFC2253 | awk -F , '{print $2}' | awk -F = '{print $2}')

CREDENTIAL_URL=$(openssl x509 -in zymkey.crt -noout -subject -nameopt RFC2253 | awk -F , '{print $3}' | awk -F = '{print $2}')

REGION=$(openssl x509 -in zymkey.crt -noout -subject -nameopt RFC2253 | awk -F , '{print $4}' | awk -F = '{print $2}')

echo Thing Name: $THING_NAME
echo Role Alias: $ROLE_ALIAS
echo Credential: $CREDENTIAL_URL
echo AWS Region: $REGION
read -p "Want to continue? [Y/n]: " continue
[ "$continue" != "Y" ] && exit 1






#SETUP AWS IOT
#Activate cert in AWS IoT
aws iot register-certificate --certificate-pem file:///opt/zymbit/device.crt --ca-certificate-pem file:///opt/zymbit/root.ca/pem --set-as-active
#CERTIFICATE_ARN =$(jq --raw-output .credentials.accessKeyId <(echo $CREDENTIALS))

#Create a thing with a unique name
aws iot create-thing --thing-name $THING_NAME

#Attach thing to certificate ARN
aws iot create-thing --thing-name $THING_NAME

#Attach policy to certificate ARN

#Create ~/.aws/config file

#Update values in /opt/zymbit/credentials.sh

#Ensure /opt/zymbit/credentials.sh is readable and executable for the account that needs the credentials
#chmod +x /opt/zymbit/credentials.sh

#Run the /opt/zymbit/credentials.sh script
#sudo /opt/zymbit/credentials.sh
