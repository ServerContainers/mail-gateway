
# Cheat Sheet

## Create a self-signed ssl cert

Please note, that the Common Name (CN) is important and should be the FQDN to the secured server:

    openssl req -x509 -newkey rsa:4086 \
    -keyout key.pem -out cert.pem \
    -days 3650 -nodes -sha256

## Generate Cert fingerprint

    openssl x509 -noout -fingerprint -in cert.pem

## Example relay_clientcerts

    AA:BB:CC:DD:EE:FF:12:34:56:67:2E:FB:3F:34:99:90:AB:CD:EF:4C trusted.mailserver.example.tld

## Create a Simple CA with openssl

    # generate CA cert & key
    openssl genrsa -out rootCA.key 4096
    openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 1024 -out rootCA.pem

    # create csr
    openssl genrsa -out device.key 4096
    openssl req -new -key device.key -out device.csr

    # sign csr with CA
    openssl x509 -req -in device.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out device.crt -days 500 -sha256

## Postfix SSL Configuration

    ##### TLS settings ######

    ### outgoing connections ###
    # smtp_tls_security_level=encrypt # for secure connections only
    smtp_tls_security_level=may
    smtp_tls_cert_file=/etc/postfix/tls/bundle.crt
    smtp_tls_key_file=/etc/postfix/tls/cert.key

    smtp_tls_exclude_ciphers = aNULL, DES, RC4, MD5, 3DES
    smtp_tls_mandatory_exclude_ciphers = aNULL, DES, RC4, MD5, 3DES
    smtp_tls_protocols = !SSLv2 !SSLv3
    smtp_tls_mandatory_protocols = !SSLv2, !SSLv3
    smtp_tls_mandatory_ciphers=high

    smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache
    smtp_tls_loglevel = 1

    ### incoming connections ###
    # smtpd_tls_security_level=encrypt # for secure connections only
    smtpd_tls_security_level=may
    smtpd_tls_cert_file=/etc/postfix/tls/bundle.crt
    smtpd_tls_key_file=/etc/postfix/tls/cert.key

    smtpd_tls_exclude_ciphers = aNULL, DES, RC4, MD5, 3DES
    smtpd_tls_mandatory_exclude_ciphers = aNULL, DES, RC4, MD5, 3DES
    smtpd_tls_protocols = !SSLv2 !SSLv3
    smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3
    smtpd_tls_mandatory_ciphers=high

    smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache
    smtpd_tls_loglevel = 1


## Enable Postfix Cert Authentication

    postconf -e smtpd_tls_ask_ccert=yes
    postconf -e smtpd_tls_CAfile=/etc/postfix/tls/rootCA.crt
    postconf -e smtpd_recipient_restrictions=permit_mynetworks,permit_tls_all_clientcerts,reject_unauth_destination
