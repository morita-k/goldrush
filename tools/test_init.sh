#!/bin/sh

bundle install
bundle update
tools/test_init_db.sh localhost grtest

