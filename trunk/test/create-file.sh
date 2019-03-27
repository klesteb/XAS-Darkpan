#!/bin/sh
#
if [ $# -eq 0 ]
then
    echo "usage: create-file.sh \"id\""
    exit 1
fi
#
curl -v http://localhost:8081/api/create/$1 -XPOST -H "Content-Type: text/plain" -u kevin
#
