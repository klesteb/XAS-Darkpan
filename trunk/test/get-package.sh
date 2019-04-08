#!/bin/sh
#
curl -v -u kevin http://localhost:8081/api/packages/$1 -H "Accept: application/hal+json" | json_xs
#
