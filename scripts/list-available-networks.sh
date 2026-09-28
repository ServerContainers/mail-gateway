#!/bin/sh
# Print every network this container is directly attached to, one per line,
# in Postfix mynetworks notation (IPv4 a.b.c.d/n, IPv6 [prefix]/n).
# Used by AUTO_TRUST_NETWORKS.
#
# Connected routes are exactly the attached networks, with the host bits
# already zeroed — no netmask arithmetic, and IPv6 works the same way.
# Link-local and multicast IPv6 prefixes are never trusted.

echo "127.0.0.0/8"
ip -4 route show 2>/dev/null \
  | awk '$1 ~ /\// && $1 != "default" && !/ via / { print $1 }'

grep -q . /proc/net/if_inet6 2>/dev/null || exit 0
echo "[::1]/128"
ip -6 route show 2>/dev/null \
  | awk '$1 ~ /\// && $1 != "default" && !/ via / && $1 !~ /^(fe80|ff[0-9a-f][0-9a-f]):/ {
           split($1, p, "/"); print "[" p[1] "]/" p[2] }'
