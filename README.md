# AWS Integration with Zymbit

## Process

### Device Process
- Generate CSR with Zymkey
  - The CSR contains specific device info
- Sign CSR with private CA
- Put device cert and root CA cert onto device
- Register device cert in AWS with root CA cert
- Create a IoT Thing in AWS
- Attach thing to device cert
- Attach policy to device cert
- Curl credential provider url using TLS to receive AWS device credentials

### Global Setup
- Create a private CA
- Register private CA with AWS
- Create an IAM role with GetRole and PassRole permissions
- Create a role trust policy for credentials provider to assume this role
- Create a role alias linked to IAM role
- Create an IoT policy which allows role alias to be assumed with a certificate
