#!/bin/bash
set -e

SCRIPT_NAME=$(basename $0)

[ -z $2 ] && echo "${SCRIPT_NAME} <csr filename> <crt filename>" 1>&2 && exit 1

csr=$1
crt=$2
openssl x509 -req -SHA256 -days 3650 \
  -CA CA_files/zk_ca.crt -CAkey CA_files/zk_ca.key -CAcreateserial \
  -in ${csr} -out ${crt}
