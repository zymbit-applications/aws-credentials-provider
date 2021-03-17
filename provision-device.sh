#!/usr/bin/env bash

#PREREQUISITES

#1. Make certificate from zymkey
  # $ openssl req -key nonzymkey.key -new -out zymkey.csr -engine zymkey_ssl -keyform e 
  #Country Name (2 letter code) [AU]:
  #State or Province Name (full name) [Some-State]:<IoT POLICY>
  #Locality Name (eg, city) []:<REGION>
  #Organization Name (eg, company) [Internet Widgits Pty Ltd]:<CREDENTIAL URL> (cxxxxxxxxxxxxx)
  #Organizational Unit Name (eg, section) []:<ROLE ALIAS>
  #Common Name (e.g. server FQDN or YOUR name) []:<THING NAME>
  #Email Address []:

#2. Sign csr with private CA
#3. Put device.crt into /opt/zymbit/device.crt
#4. Put root.ca.pem into /opt/zymbit/root.ca.pem

DEVICE_CERT=/opt/zymbit/device.crt
CA_CERT=/opt/zymbit/root.ca.pem
CONFIG=~/.aws/config

#Ensure device cert is in /opt/zymbit/device.crt
test ! -f $DEVICE_CERT && echo "$DEVICE_CERT does not exist." && exit 1

#Ensure root CA pem file is in /opt/zymbit/root.ca.pem
test ! -f $CA_CERT && echo "$CA_CERT does not exist." && exit 1

#Ensure ~/.aws/config file is correct
test ! -f $CONFIG && echo "$CONFIG does not exist." && exit 1


#GET DEVICE INFO
THING_NAME=$(openssl x509 -in $DEVICE_CERT -noout -subject -nameopt RFC2253 | awk -F , '{print $1}' | awk -F = '{print $3}')

ROLE_ALIAS=$(openssl x509 -in $DEVICE_CERT -noout -subject -nameopt RFC2253 | awk -F , '{print $2}' | awk -F = '{print $2}')

CREDENTIAL_URL=$(openssl x509 -in $DEVICE_CERT -noout -subject -nameopt RFC2253 | awk -F , '{print $3}' | awk -F = '{print $2}')

REGION=$(openssl x509 -in $DEVICE_CERT -noout -subject -nameopt RFC2253 | awk -F , '{print $4}' | awk -F = '{print $2}')

IOT_POLICY=$(openssl x509 -in $DEVICE_CERT -noout -subject -nameopt RFC2253 | awk     -F , '{print $5}' | awk -F = '{print $2}')

echo Thing Name: $THING_NAME
echo Role Alias: $ROLE_ALIAS
echo Credential: $CREDENTIAL_URL
echo AWS Region: $REGION
echo IoT Policy: $IOT_POLICY
read -p "Want to continue? [Y/n]: " continue
[ "$continue" != "Y" ] && exit 1
echo ""



#Check if the region in device cert is the same as aws cli config file
CONFIG_REGION=$(grep region $CONFIG | awk -F = '{print $2}')
test $CONFIG_REGION != $REGION && echo "$CONFIG and $DEVICE_CERT have different regions." && exit 1
cat $CONFIG
read -p "Are these values correct? [Y/n]: " continue
[ "$continue" != "Y" ] && exit 1
echo ""



#SETUP AWS IOT THING

#Activate cert in AWS IoT
AWS_CERT=$(aws iot register-certificate --certificate-pem file://$DEVICE_CERT --ca-certificate-pem file://$CA_CERT --set-as-active)
CERT_ARN=$(jq --raw-output .certificateArn <(echo $AWS_CERT))
CERT_ID=$(jq --raw-output .certificateId <(echo $AWS_CERT))

#Create the thing 
aws iot create-thing --thing-name $THING_NAME &> /dev/null
echo Created thing $THING_NAME

#Attach thing to certificate ARN
aws iot attach-thing-principal --thing-name $THING_NAME --principal $CERT_ARN
echo Attached certificate to $THING_NAME

#Attach policy to certificate ARN
aws iot get-policy --policy-name $IOT_POLICY &> /dev/null
test $? != 0 && echo "No policy $IOT_POLICY in AWS IoT." && exit 1
aws iot attach-policy --policy-name $IOT_POLICY --target $CERT_ARN
echo Attached $IOT_POLICY to $THING_NAME
echo SUCCESS
