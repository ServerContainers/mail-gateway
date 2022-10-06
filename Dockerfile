FROM debian:bullseye

ENV PATH="/container/scripts:${PATH}"
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -q -y update \
 && apt-get -q -y install --no-install-recommends runit \
                          telnet net-tools postfix rsyslog \
                          clamav clamav-daemon amavisd-new spamassassin razor pyzor \
                          arj bzip2 cabextract cpio file gzip nomarch pax unzip zip \
                          opendkim opendkim-tools \
 && apt-get -q -y clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
 \
 && mkdir -p /var/run/clamav \
 && chown clamav.clamav -R /var/run/clamav \
 \
 && head -n $(grep -n RULES /etc/rsyslog.conf | cut -d':' -f1) /etc/rsyslog.conf > /etc/rsyslog.conf.new \
 && mv /etc/rsyslog.conf.new /etc/rsyslog.conf \
 && echo '*.*        /dev/stdout' >> /etc/rsyslog.conf \
 && sed -i '/imklog/d' /etc/rsyslog.conf \
 \
 && adduser clamav amavis

# Postfix

RUN openssl dhparam -out /etc/postfix/dh1024.pem 1024 \
 && openssl dhparam -out /etc/postfix/dh512.pem 512 

# ClamAV

RUN timeout 500 freshclam || true

# razor & pyzor

RUN su - amavis -s /bin/bash -c 'razor-admin -create; razor-admin -register; pyzor discover'

COPY . /container/

VOLUME ["/etc/postfix/tls", "/etc/postfix/additional"]
HEALTHCHECK CMD ["/container/scripts/docker-healthcheck.sh"]
ENTRYPOINT ["entrypoint.sh"]

CMD [ "runsvdir","-P", "/etc/service" ]