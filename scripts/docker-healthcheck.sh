#!/bin/bash

# Check for changes to certificates, reload postfix if different.
diff /etc/postfix/tls /tmp/tls
if [ $? -ne 0 ]; then
  postfix reload
  rm -rf /tmp/tls 2> /dev/null
  cp -a /etc/postfix/tls /tmp/tls
fi

[[ $(ps aux | grep '[r]unsvdir\|[r]syslogd\|[s]bin/master' | wc -l) -ge '3' ]]
exit $?