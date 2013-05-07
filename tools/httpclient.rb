require 'rubygems'
require 'httpclient'

def main
  # 第一引数はURL
  url = ARGV.shift
  # 第二引数以降、key=value形式でパラメータが渡される形式
  params = {"login" => 'goldrush', "password" => 'furuponpon'}
  ARGV.each do |arg|
    pr = str_to_hash(arg)
    params.merge! str_to_hash(arg)
  end
  # パラメータにSTDIN=[パラメータ名]とあったらSTDINからの入力をパラメータとして渡すモード
  if params['STDIN'] != nil
    params[params['STDIN'].to_s.strip] = STDIN.read
  end
  
  # httpclientを利用したサーバー呼び出し
  around_http_client do |agent|
    res = agent.post url, params
  end
end

def around_http_client(&block)
  # HTTP Clientの準備
#  api_logfile = File.open(File.join('log',"cloud_api_call.#{Process.pid}.log"), "a")
  agent = HTTPClient.new
  agent.receive_timeout = 300
#  agent.debug_dev = STDOUT
#  agent.debug_dev = api_logfile
  block.call agent
ensure
#  agent.debug_dev = nil
#  api_logfile.close
end

def str_to_hash(str, separator="=")
  k,v = str.split(separator)
  return {k.to_s.strip => v.to_s.strip}
end

main
