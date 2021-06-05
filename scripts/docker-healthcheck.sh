#!/bin/sh
diff /etc/postfix/tls /tmp/tls || exit 2

[[ $(ps aux | grep '[r]unsvdir\|[r]syslogd\|[s]bin/master' | wc -l) -ge '3' ]]
exit $?