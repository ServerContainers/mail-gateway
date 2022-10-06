#!/bin/bash

[[ $(ps aux | grep '[r]unsvdir\|[r]syslogd\|[s]bin/master' | wc -l) -ge '3' ]]
exit $?