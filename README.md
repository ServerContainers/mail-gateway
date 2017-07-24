# Docker Mail Gateway Postfix (servercontainers/mail-gateway)
_maintained by ServerContainers_

[FAQ - All you need to know about the servercontainers Containers](https://marvin.im/docker-faq-all-you-need-to-know-about-the-marvambass-containers/)

## What is it

This Dockerfile (available as ___servercontainers/mail-gateway___) gives you a Postfix Configured for the following scenarios.

- Smarthost Configuration (Outgoing Mails for trusted nodes with random IP)
    - _let your internal mailserver send mails through this container encrypted and authenticated via ssl client authentication_
- Incoming Mail Spamfilter/Virusscanner (Amavis) Gateway
    - _you can also put this container in front of your mailbox handling server and let this container do the spam/virus checks_
- Incoming Mail Gateway
    - _let this gateway do caching and loadbalancing_
- Outgoing Mail Gateway and DKIM signer
    - _sign your mails even for multiple domains with DKIM automatically_
- Outgoing Mail Gateway for Docker Containers connected to this container via networks
    - _this container is capable of automatically trusting all networks it's connected to_
- Outgoing Mail for specified Networks
    - _trust specified Networks_

For Configuration of the Server you use environment Variables and volume files.

It's based on the [debian:jessie](https://registry.hub.docker.com/_/debian:jessie/) Image

View in Docker Registry [servercontainers/mail-gateway](https://registry.hub.docker.com/u/servercontainers/mail-gateway/)

View in GitHub [ServerContainers/mail-gateway](https://github.com/ServerContainers/mail-gateway)

### What it's not

This container is not meant to be used as a mail server which stores mails and handles mailboxes.
Just put this container in between the outside world and your mailbox handeling mail server.


## Environment variables

- POSTFIX_SMTPD_BANNER

## Volumes

- /etc/postfix/tls
    - this is where the container looks for:
        - dh1024.pem (to overwrite the one generated at container build)
        - dh512.pem (to overwrite the one generated at container build)
        - rootCA.crt (to check valid client certificates against)
        - client.crt (outgoing SSL Client cert)
        - client.key (outgoing SSL Client key)
        - bundle.crt (incoming SSL Server cert/bundle)
        - cert.key (incoming SSL Server key)
- /etc/postfix/additional
    - this is where the container looks for:
        - opendkim (folder - enables opendkim support if it exists - but needs __DKIM\_DOMAINS__ env)
        - transport (postfix transport text-file - without been postmaped)

# Cheat Sheet

## DKIM

This Server enables you to use DKIM for multiple Domains by default.

To use it just add your domains to the __DKIM\_DOMAINS__ environment variable.
_DKIM\_DOMAINS: example.com myotherdomain.tld_

and make sure the folder _/etc/postfix/additional/opendkim_ is available from within the container (/etc/postfix/additional is a volume).

After that the DKIM Keys will be generated automatically if necessary.
All DKIM Public Informations for your DNS Servers will be printed to the Docker Logs.

So you start the container wait for the Public Keys to appear in the Docker logs and add them to the Domains in your DNS System.

### DKIM manually (for a single Domain)

_You don't need the next steps, but they are great to understand how DKIM works_

_If you want to know how the multi domain handeling is done just take a look at the containers github repository_

To generate DKIM keys you'll need the opendkim tools

```
$ apt-get install opendkim-tools
```

This generates a new certificate for `@example.com` with selector `-s mail`. If you want to Test DKIM first, add `-t` argument which stands for test-mode.

```
$ opendkim-genkey -s mail -d example.com
```

Just put the file _mail.private_ as _dkim.key_ inside the dkim directory you'll later link into the container using _-v_.

The `mail.txt` should be imported into the DNS System. Add a new _TXT-Record_ for _mail_.\_domainkey [selector.\_domainkey]. And add as value the String starting "`v=DKIM1;...`" from the `mail.txt` file.

Example:

```
$ cat mail.txt
mail._domainkey	IN	TXT	( "v=DKIM1; k=rsa; "
	  "p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDcUp8Q1sbxgnR2iL7w+TOHN1IR6PzAP3vmUoPfeN07NGfWo8Wzxyn+hqqnC+mbPOW4ZDoAiu5dvpPsCt1RQalwBw/iPlB/8ScTlPGRpsTLo4ruCDL+yVkw32/UhvCL8vbZxM/Q7ELjO6AqRRW/KuCvbd5gNRYGeyjWd+UQAfmBJQIDAQAB" )  ; ----- DKIM key mail for example.com
```

You need to put this line in your `example.com` DNS config zone:

```
mail._domainkey	IN	TXT	"v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDcUp8Q1sbxgnR2iL7w+TOHN1IR6PzAP3vmUoPfeN07NGfWo8Wzxyn+hqqnC+mbPOW4ZDoAiu5dvpPsCt1RQalwBw/iPlB/8ScTlPGRpsTLo4ruCDL+yVkw32/UhvCL8vbZxM/Q7ELjO6AqRRW/KuCvbd5gNRYGeyjWd+UQAfmBJQIDAQAB"
```

Thats all you need for DKIM

Check DNS config:

```
$ host -t TXT mail._domainkey.example.com
mail._domainkey.example.com descriptive text "v=DKIM1\; k=rsa\; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDcUp8Q1sbxgnR2iL7w+TOHN1IR6PzAP3vmUoPfeN07NGfWo8Wzxyn+hqqnC+mbPOW4ZDoAiu5dvpPsCt1RQalwBw/iPlB/8ScTlPGRpsTLo4ruCDL+yVkw32/UhvCL8vbZxM/Q7ELjO6AqRRW/KuCvbd5gNRYGeyjWd+UQAfmBJQIDAQAB"
```

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
