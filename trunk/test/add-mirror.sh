#!/bin/sh
#
if [ $# -eq 0 ]
then
    echo "usage: add-mirror.sh <filename>"
    exit 1
fi
#
curl -v http://localhost:8081/api/mirrors -XPOST -T$1 -H "Content-Type: application/json" -u kevin --no-keepalive 
#
