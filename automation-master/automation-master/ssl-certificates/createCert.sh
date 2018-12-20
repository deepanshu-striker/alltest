#!/bin/bash -x

mkdir -p ca/root-ca/private ca/root-ca/db crl certs
chmod 700 ca/root-ca/private
cp /dev/null ca/root-ca/db/root-ca.db
cp /dev/null ca/root-ca/db/root-ca.db.attr
echo 01 > ca/root-ca/db/root-ca.crt.srl
echo 01 > ca/root-ca/db/root-ca.crl.srl
openssl req -new \
    -config etc/root-ca.conf \
    -out ca/root-ca.csr \
    -keyout ca/root-ca/private/root-ca.key
	
openssl ca -selfsign \
    -config etc/root-ca.conf \
    -in ca/root-ca.csr \
    -out ca/root-ca.crt \
    -extensions root_ca_ext \
    -enddate 20301231235959Z

openssl ca -gencrl \
    -config etc/root-ca.conf \
    -out crl/root-ca.crl

mkdir -p ca/tls-ca/private ca/tls-ca/db crl certs
chmod 700 ca/tls-ca/private	

cp /dev/null ca/tls-ca/db/tls-ca.db
cp /dev/null ca/tls-ca/db/tls-ca.db.attr
echo 01 > ca/tls-ca/db/tls-ca.crt.srl
echo 01 > ca/tls-ca/db/tls-ca.crl.srl

openssl req -new \
    -config etc/tls-ca.conf \
    -out ca/tls-ca.csr \
    -keyout ca/tls-ca/private/tls-ca.key
	
openssl ca \
    -config etc/root-ca.conf \
    -in ca/tls-ca.csr \
    -out ca/tls-ca.crt \
    -extensions signing_ca_ext
	
openssl ca -gencrl \
    -config etc/tls-ca.conf \
    -out crl/tls-ca.crl

cat ca/tls-ca.crt ca/root-ca.crt > \
    ca/tls-ca-chain.pem

SAN=DNS:trilio.test,DNS:tvault-controller.trilio.test \
openssl req -new \
    -config etc/server.conf \
    -out certs/tvault-controller.trilio.test.csr \
    -keyout certs/tvault-controller.trilio.test.key

	
openssl ca \
    -config etc/tls-ca.conf \
    -in certs/tvault-controller.trilio.test.csr \
    -out certs/tvault-controller.trilio.test.crt \
    -extensions server_ext
