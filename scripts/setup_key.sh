#!/bin/bash

set -u

#host="https://jenkins.apps.cxl-server.home.lan"
host="https://jenkins.cxl.epac.to"

get_cert() {
  local url=${1#*://}
  url=${url%/*}:443
  openssl s_client -connect "${url}" </dev/null 2>/dev/null | \
    sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > jenkins-cli.cer
}

get_cert "${host}"

pass=$(dd if=/dev/urandom bs=1 count=4096 2>/dev/null | sha512sum - | awk '{print $1}')

unset _JAVA_OPTIONS

# Setup java keystore
keytool \
  -import \
  -noprompt \
  -trustcacerts \
  -alias jenkins-cli \
  -file jenkins-cli.cer \
  -keystore jenkins-cli.ks \
  -storepass "${pass}"

keytool \
  -list \
  -v \
  -keystore jenkins-cli.ks \
  -storepass "${pass}"

cat <<EOF
################################################################################

Upload the following files to the remote host:
  * jenkins-cli.cer  - HTTPS certificate for ${host}
  * jenkins-cli.ks   - Java keystore containing the certificate

Password for keystore: ${pass}

Java should be invoked with the following command:

  $ java -Djavax.net.ssl.trustStore=jenkins-cli.ks -Djavax.net.ssl.trustStorePassword=PASSWORD
EOF
