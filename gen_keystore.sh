#!/usr/bin/env bash

if [ $# -ne 5 ]; then
    echo "Usage: $0 <IN_KEY_FILENAME> <IN_CERT_FILENAME> <IN_CA_CERT_FILENAME> <OUT_KEYSTORE_FILENAME> <OUT_KEYSTORE_PASSWORD>"
    echo "Example: $0 key.pem cert.pem cacert.pem keystore.jks keystore_password"
    exit 1
fi

KEY=$1
PKCS8_KEY=$(mktemp)
CERTIFICATE=$2
CA_CERTIFICATE=$3
KEYSTORE_FILE=$4
KEYSTORE_PASSWORD=$5
FULL_CHAIN_CERTIFICATE=$(mktemp)
P12_KEY_AND_FULL_CHAIN_CERTIFICATE=$(mktemp)
P12_ALIAS="certificate"
KEYTOOL_ALIAS="certificate"
P12_PASSWORD=$(cat /dev/random | LC_CTYPE=C tr -dc "[:alpha:]" | head -c 8)

cat $CERTIFICATE $CA_CERTIFICATE > $FULL_CHAIN_CERTIFICATE

openssl pkcs8 \
        -topk8 -nocrypt \
        -in $KEY \
        -out $PKCS8_KEY

openssl pkcs12 \
        -export \
        -in $FULL_CHAIN_CERTIFICATE -inkey $PKCS8_KEY \
        -out $P12_KEY_AND_FULL_CHAIN_CERTIFICATE -passout pass:$P12_PASSWORD \
        -name $P12_ALIAS

keytool -importkeystore \
        -deststorepass clojure -destkeypass $KEYSTORE_PASSWORD \
        -destkeystore $KEYSTORE_FILE \
        -srckeystore $P12_KEY_AND_FULL_CHAIN_CERTIFICATE -srcstoretype PKCS12 -srcstorepass $P12_PASSWORD \
        -alias $KEYTOOL_ALIAS

rm -f $PKCS8_KEY
rm -f $FULL_CHAIN_CERTIFICATE
rm -f $P12_KEY_AND_FULL_CHAIN_CERTIFICATE
