#!/bin/sh
cat << EOS > config/database.yml
test:
  adapter: mysql2
  encoding: utf8
  reconnect: false
  hostname: $1
  database: $2
  username: $2
  password: $2
  pool: 5

EOS

