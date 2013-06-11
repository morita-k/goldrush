#!/bin/sh

cur=`dirname $0`

bundle install
bundle update
$cur/test_init_db.sh $1 $2

