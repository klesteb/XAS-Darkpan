#!/bin/sh
#
if [ $# -eq 0 ]
then
    echo "usage: del-author.sh \"id\""
    exit 1
fi
curl -v http://localhost:8081/api/authors/$1 -XDELETE -u kevin
