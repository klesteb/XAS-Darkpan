#!/bin/sh
#
curl -v -u kevin http://localhost:8080/api/authors -H "Accept: application/hal+json" | json_xs

