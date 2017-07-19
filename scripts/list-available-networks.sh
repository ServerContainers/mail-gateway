#!/bin/bash

function getNetworkFromAddressAndNetmask {
  IFS=. read -r i1 i2 i3 i4 <<< "$1"
  IFS=. read -r m1 m2 m3 m4 <<< "$2"
  printf "%d.%d.%d.%d\n" "$((i1 & m1))" "$((i2 & m2))" "$((i3 & m3))" "$((i4 & m4))"
}

function getCidrSuffixFromNetmask {
    nbits=0
    IFS=.
    for dec in $1 ; do
        case $dec in
            255) let nbits+=8;;
            254) let nbits+=7;;
            252) let nbits+=6;;
            248) let nbits+=5;;
            240) let nbits+=4;;
            224) let nbits+=3;;
            192) let nbits+=2;;
            128) let nbits+=1;;
            0);;
            *) echo "Error: $dec is not recognised"; exit 1
        esac
    done
    echo "$nbits"
}


IFS=$'\n'       # make newlines the only separator
for j in $(ifconfig | grep inet | tr ' ' '\n' | grep 'Mask\|add' | tr '\n' ' ' | sed 's/addr/\naddr/g' | grep . | sed 's/[^0-9. ]//g')
do
  ADDR=$(echo "$j" | cut -d' ' -f1)
  MASK=$(echo "$j" | cut -d' ' -f2)

  NETWORK=$(getNetworkFromAddressAndNetmask "$ADDR" "$MASK")
  CIDR=$(getCidrSuffixFromNetmask "$MASK")

  echo "$NETWORK/$CIDR"
done
