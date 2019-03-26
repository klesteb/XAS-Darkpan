#!/bin/sh
#
if [ $# -eq 0 ]
then
    echo "usage: upd-author.sh <id> <update file>"
    exit 1
fi
#
curl -v http://localhost:8081/api/authors/$1 -XPUT -T$2 -H "Content-Type: application/json" -u kevin --no-keepalive 

