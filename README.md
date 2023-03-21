# Docker Mail Gateway Postfix - (ghcr.io/servercontainers/mail-gateway) [x86 + arm]
_maintained by ServerContainers_

## IMPORTANT!

In March 2023 - Docker informed me that they are going to remove my 
organizations `servercontainers` and `desktopcontainers` unless 
I'm upgrading to a pro plan.

I'm not going to do that. It's more of a professionally done hobby then a
professional job I'm earning money with.

In order to avoid bad actors taking over my org. names and publishing potenial
backdoored containers, I'd recommend to switch over to my new github registry: `ghcr.io/servercontainers`.

## Build & Variants

You can specify `DOCKER_REGISTRY` environment variable (for example `my.registry.tld`)
and use the build script to build the main container and it's variants for _x86_64, arm64 and arm_

You'll find all images tagged like `d11.2-p3.5.6-1_b1` which means `d<debian version>-p<postfix version (with some esacped chars)>`.
This way you can pin your installation/configuration to a certian version. or easily roll back if you experience any problems
(don't forget to open a issue in that case ;D).

To build a `latest` tag run `./build.sh release`

## Changelogs

* 2023-03-20
    * github action to build container
    * implemented ghcr.io as new registry
* 2023-03-18
    * switched from docker hub to a build-yourself container
* 2022-01-08
    * new build script
    * version tagging
    * update to debian `bullseye`
* 2021-07-28
    * healthcheck will fail if certificate is 3 days or less valid or already expired
* 2021-06-04
    * added healthcheck (will fail when certs are updated without container restart)
* 2020-12-01
    * fixed broken containers/build
    * better tls settings (tls 1.3 support)
* 2020-11-05
    * multiarch build

## What is it

This Dockerfile (available as self-build-container) gives you a Postfix Configured for the following scenarios.

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

It's based on the [debian:bullseye](https://registry.hub.docker.com/_/debian/) Image

View in GitHub Registry [ghcr.io/servercontainers/mail-gateway](https://ghcr.io/servercontainers/mail-gateway)

View in GitHub [ServerContainers/mail-gateway](https://github.com/ServerContainers/mail-gateway)

_currently tested on: x86_64, arm64, arm_


### What it's not

This container is not meant to be used as a mail server which stores mails and handles mailboxes.
Just put this container in between the outside world and your mailbox handeling mail server.
Take a look at [ServerContainers/mail-box](https://github.com/ServerContainers/mail-box) for a mail server with mailbox/imap handling.

## Environment variables

__OFFICIAL ENVIRONMENT VARIABLES__

- MAIL_FQDN
    - specify the mailserver name - only add FQDN not a hostname!
    - e.g. _my.mailserver.example.com_
- POSTFIX_SMTPD_BANNER
    - alter the SMTPD Banner of postfix e.g. _mailserver.example.local ESMTP_

- AUTO_TRUST_NETWORKS
    - add all networks this container is connected to and trust them to send mails
    - _set to any value to enable_
- ADDITIONAL_MYNETWORKS
    - add this specific network to the automatically trusted onces
    - set to `0.0.0.0/0` to make this an open relay
- MYNETWORKS
    - ignore all auto configured _mynetworks_ and replace them with this value
    - _overwrites networks specified in ADDITIONAL_MYNETWORKS_

- RELAYHOST
    - sets postfix relayhost - please take a look at the official documentation
    - _The form enclosed with [] eliminates DNS MX lookups. Don't worry if you don't know what that means. Just be sure to specify the [] around the mailhub hostname that your ISP gave to you, otherwise mail may be mis-delivered._

- DISABLE_AMAVIS
    - disable spam and virus checks (also disables the services so only postfix and needed services get started)
    - might be useful if you only get trusted e-mails
    - _set to any value to disable_
- DISABLE_VIRUS_CHECKS
    - disables virus scanning/checks (also disabled clamd and freshclam)
    - _set to any value to disable_
- DISABLE_SPAM_CHECKS
    - disables spam checking
    - _set to any value to disable_

- AMAVIS_SA_TAG_LEVEL_DEFLT
    - amavis setting _sa_tag_level_deflt_ - default _undef_
- AMAVIS_SA_TAG2_LEVEL_DEFLT
    - amavis setting _sa_tag2_level_deflt_ - default _5_
- AMAVIS_SA_KILL_LEVEL_DEFLT
    - amavis setting _sa_kill_level_deflt_ - default _20_

- POSTFIX_SSL_OUT_CERT
    - path to SSL Client certificate (outgoing connections)
    - default: _/etc/postfix/tls/client.crt_
- POSTFIX_SSL_OUT_KEY
    - path to SSL Client key (outgoing connections)
    - default: _/etc/postfix/tls/client.key_
- POSTFIX_SSL_OUT_SECURITY_LEVEL
    - SSL security level for outgoing connections
    - default: _may_

- POSTFIX_SSL_IN_CERT
    - path to SSL Cert/Bundle (incoming connections)
    - default: _/etc/postfix/tls/bundle.crt_
- POSTFIX_SSL_IN_KEY
    - path to SSL Cert key (incoming connections)
    - default: _/etc/postfix/tls/cert.key_
- POSTFIX_SSL_IN_SECURITY_LEVEL
    - SSL security level for incoming connections
    - default: _may_

- POSTFIX_SSL_IN_CERT_FINGERPRINTS
    - trusted incoming certificate fingerprints (multiline) (which clients are authenticated)
    - e.g.: _AA:BB:CC:DD:EE:FF:12:34:56:67:2E:FB:3F:34:99:90:AB:CD:EF:4C trusted.mailserver.example.tld_

- POSTFIX_QUEUE_LIFETIME_BOUNCE
    - The  maximal  time  a  BOUNCE MESSAGE is queued before it is considered undeliverable
    - By default, this is the same as the queue life time for regular mail
- POSTFIX_QUEUE_LIFETIME_MAX
    - maximum lifetime of regular (non bounce) messages

- POSTFIX_RELAY_DOMAINS
    - specify certain domains which will be relayed (by default all mails will be forwarded)
- POSTFIX_MYDESTINATION
    - specify the domains which this mail-gateway handles (I recommend to use only POSTFIX_RELAY_DOMAINS)

__HIGH PRIORITY ENVIRONMENT VARIABLE__

the following variable/s are only if you have some specific settings you need.
They help you overwrite everything after the config was generated.
If you can update your setting with the variables from above, it is strongly recommended to use them!

_some characters might brake your configuration!_

- POSTFIX_RAW_CONFIG_<POSTFIX_SETTING_NAME>
    - set/edit all configurations in /etc/postfix/main.cf using the POSTFIX_RAW_CONFIG_ followed by the setting name

_for example: to set_ ___mynetworks_style = subnet___ _just add a environment variable_ ___POSTFIX_RAW_CONFIG_MYNETWORKS_STYLE=subnet___

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
        - header_checks (postfix header_checks regex file)

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
    smtp_tls_security_level=$POSTFIX_SSL_OUT_SECURITY_LEVEL
    smtp_tls_cert_file=$POSTFIX_SSL_OUT_CERT
    smtp_tls_key_file=$POSTFIX_SSL_OUT_KEY

    smtp_tls_exclude_ciphers = aNULL, DES, RC4, MD5, 3DES
    smtp_tls_mandatory_exclude_ciphers = aNULL, DES, RC4, MD5, 3DES

    smtp_tls_mandatory_ciphers=medium

    smtp_tls_protocols = TLSv1.3 TLSv1.2, !TLSv1.1, !TLSv1, !SSLv2, !SSLv3
    smtp_tls_mandatory_protocols = TLSv1.3 TLSv1.2, !TLSv1.1, !TLSv1, !SSLv2, !SSLv3

    smtp_tls_session_cache_database = btree:\${data_directory}/smtp_scache
    smtp_tls_loglevel = 1

    ### incoming connections ###
    # smtpd_tls_security_level=encrypt # for secure connections only
    smtpd_tls_security_level=$POSTFIX_SSL_IN_SECURITY_LEVEL
    smtpd_tls_cert_file=$POSTFIX_SSL_IN_CERT
    smtpd_tls_key_file=$POSTFIX_SSL_IN_KEY

    smtpd_tls_exclude_ciphers = aNULL, DES, RC4, MD5, 3DES
    smtpd_tls_mandatory_exclude_ciphers = aNULL, DES, RC4, MD5, 3DES

    smtpd_tls_mandatory_ciphers=high

    smtpd_tls_protocols = TLSv1.3 TLSv1.2, !TLSv1.1, !TLSv1, !SSLv2, !SSLv3
    smtpd_tls_mandatory_protocols = TLSv1.3 TLSv1.2, !TLSv1.1, !TLSv1, !SSLv2, !SSLv3

    smtpd_tls_session_cache_database = btree:\${data_directory}/smtpd_scache
    smtpd_tls_loglevel = 1


## Enable Postfix Cert Authentication

    postconf -e smtpd_tls_ask_ccert=yes
    postconf -e smtpd_tls_CAfile=/etc/postfix/tls/rootCA.crt
    postconf -e smtpd_recipient_restrictions=permit_mynetworks,permit_tls_all_clientcerts,reject_unauth_destination
