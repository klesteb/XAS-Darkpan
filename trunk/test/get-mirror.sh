#!/bin/sh
#
curl -v -u kevin http://localhost:8081/api/mirrors/$1 -H "Accept: application/hal+json" | json_xs
#
