#!/bin/sh
#
# File: create-db.sh
# Date: 18-Sep-2015
# By  : Kevin Esteb
#
# Create a new darkpan database
#

#rm /var/lib/xas/darkpan.db
export PERL5LIB=~/dev/XAS-Darkpan/trunk/lib
xas-create-schema --schema XAS::Model::Database::Darkpan
cat sql/XAS-Model-Schema-0.01-SQLite.sql | sqlite3 /var/lib/xas/darkpan.db

