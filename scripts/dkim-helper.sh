#!/bin/bash

echo ">> DKIM - Domains ($DKIM_DOMAINS)"

echo ">> DKIM - updating opendkim config"

touch /etc/postfix/additional/opendkim/KeyTable \
      /etc/postfix/additional/opendkim/SigningTable \
      /etc/postfix/additional/opendkim/TrustedHosts

cat <<EOF >> /etc/opendkim.conf

LogWhy                  yes

KeyTable                /etc/postfix/additional/opendkim/KeyTable
SigningTable            /etc/postfix/additional/opendkim/SigningTable
ExternalIgnoreList      /etc/postfix/additional/opendkim/TrustedHosts
InternalHosts           /etc/postfix/additional/opendkim/TrustedHosts
EOF

echo ">> DKIM - updating Postfix config"
cat <<EOF >> /etc/postfix/main.cf
### DKIM signing ###
milter_default_action = accept
milter_protocol = 6
smtpd_milters = inet:localhost:8891
non_smtpd_milters = inet:localhost:8891
EOF

for domain in $(echo $DKIM_DOMAINS); do
  echo ">> DKIM - enable domain: $domain"

  keydir="/etc/postfix/additional/opendkim/keys/$domain"
  if [ ! -d "$keydir" ]; then
    mkdir -p $keydir
  fi
  cd $keydir

  if [ ! -f default.private ]; then
    echo ">> generate key for domain $domain"

    opendkim-genkey -r -d $domain
    chown opendkim:opendkim default.private

    echo "default._domainkey.$domain $domain:default:$keydir/default.private" >> /etc/postfix/additional/opendkim/KeyTable
    echo "$domain default._domainkey.$domain" >> /etc/postfix/additional/opendkim/SigningTable
    echo "$domain" >> /etc/postfix/additional/opendkim/TrustedHosts
    echo ">> key for domain $domain created"
  else
    echo ">> key for domain $domain exists already"
  fi

  echo "---------------------------------------------------------------------"
  cat $keydir/default.txt
  echo "---------------------------------------------------------------------"

done
