#!/usr/bin/env bash

###############################
# Start configuration section #
###############################
CERT=/opt/zymbit/device.crt
CACERT=/opt/zymbit/root.ca.pem

THING_NAME=$(openssl x509 -in $CERT -noout -subject -nameopt RFC2253 | awk -F , '{print $1}' | awk -F = '{print $3}')
ROLE_ALIAS=$(openssl x509 -in $CERT -noout -subject -nameopt RFC2253 | awk -F , '{print $2}' | awk -F = '{print $2}')
CREDENTIAL_URL=$(openssl x509 -in $CERT -noout -subject -nameopt RFC2253 | awk -F , '{print $3}' | awk -F = '{print $2}')
REGION=$(openssl x509 -in $CERT -noout -subject -nameopt RFC2253 | awk -F , '{print $4}' | awk -F = '{print $2}')

KEY="pkcs11:object=iotkey;type=private;token=zymbit;pin-value=1234"

# This can be obtained by running - aws iot describe-endpoint --endpoint-type iot:CredentialProvider --output text
CREDENTIAL_PROVIDER_URL="$CREDENTIAL_URL.credentials.iot.$REGION.amazonaws.com"
###############################
# End configuration section   #
###############################

FULL_URL="https://"$CREDENTIAL_PROVIDER_URL"/role-aliases/"$ROLE_ALIAS"/credentials"
PKCS11_ENGINE_FOR_CURL="--engine zymkey_ssl --key-type ENG"

if [ ! -f "$CERT" ]; then
  echo "$CERT does not exist"
  exit 1
fi

if [ ! -f "$CACERT" ]; then
  echo "$CACERT does not exist"
  exit 1
fi

# No longer using the AWS IoT Verisign root CA.  If the distro doesn't have certificate authorities installed this command will probably fail
CREDENTIALS=$(curl --cacert $CACERT --cert $CERT $PKCS11_ENGINE_FOR_CURL --key $KEY -H "x-amzn-iot-thingname: $THING_NAME" $FULL_URL)

returnValue=$?

if [ $returnValue -ne 0 ]; then
  echo Failed to obtain credentials, validate the thing name, role alias name, credential provider URL, slot name '(token)', and PIN value
  echo Curl exit code: $returnValue
  echo $CREDENTIALS
  exit $returnValue
fi

export AWS_DEFAULT_REGION=$REGION
export AWS_ACCESS_KEY_ID=$(jq --raw-output .credentials.accessKeyId <(echo $CREDENTIALS))
export AWS_SECRET_ACCESS_KEY=$(jq --raw-output .credentials.secretAccessKey <(echo $CREDENTIALS))
export AWS_SESSION_TOKEN=$(jq --raw-output .credentials.sessionToken <(echo $CREDENTIALS))

EXPIRATION=$(date --date="+120 seconds" -Iseconds)

echo "{ \"Version\": 1, \"AccessKeyId\": \"$AWS_ACCESS_KEY_ID\", \"SecretAccessKey\": \"$AWS_SECRET_ACCESS_KEY\", \"SessionToken\": \"$AWS_SESSION_TOKEN\", \"Expiration\": \"$EXPIRATION\" }"
