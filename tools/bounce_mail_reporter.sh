#!/bin/sh -f

# 第一引数：環境設定ファイル
#  以下の変数が定義されている事
#    RAILS_ROOT  : railsアプリケーションのルートディレクトリへの絶対パス
#    RUBY        : rubyの実行ファイルへの絶対パス
. $1
shift 1

# 第二引数以降：Rubyスクリプトのパラメータ

umask 002

cd ${RAILS_ROOT}

BOUNCE_DATA=`${MAILBOX_PARSER} | ${RUBY} tools/yaml_reader.rb -k 0,recipient -k 0,reason`
BOUNCE_RECIPENT=`echo ${BOUNCE_DATA} | cut -f1 -d' '`
BOUNCE_REASON=`echo ${BOUNCE_DATA} | cut -f2 -d' '`

${RUBY} tools/httpclient.rb $* recipient=${BOUNCE_RECIPENT} reason=${BOUNCE_REASON}
