#!/bin/sh -f

# 第1引数：rubyへのパス

RUBY=$1
shift 1
MAILBOX_PARSER=$1
shift 1

# 第2引数以降：Rubyスクリプトのパラメータ

umask 002

cd $(dirname $0)
cd ..

BOUNCE_DATA=`tee -a /tmp/bounce.log | ${MAILBOX_PARSER} |tee -a /tmp/bounce_yaml.log | ${RUBY} tools/yaml_reader.rb -k 0,recipient -k 0,reason`
BOUNCE_RECIPENT=`echo ${BOUNCE_DATA} | cut -f1 -d' '`
BOUNCE_REASON=`echo ${BOUNCE_DATA} | cut -f2 -d' '`

${RUBY} tools/httpclient.rb $* recipient=${BOUNCE_RECIPENT} reason=${BOUNCE_REASON}
