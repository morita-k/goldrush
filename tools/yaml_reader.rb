# YAML読み込みスクリプト
# 
# 指定された検索キーを元にYAMLドキュメントから値を探索して標準出力に出力する。
#
# [第一引数]
#   読み込みファイルパス
#   * パイプ、リダイレクト時には省略
# 
# [第二引数]
#   検索キー。各階層のキーを","で区切って指定する。
#   例)
#     1,name,first_name
#   
#   処理)
#     result = data[1]['name']['first_name']
#
# [オプション]
#   -k KEYS : 複数の検索キーを同時に指定したい場合に使用する。
#             オプション引数のフォーマットは第二引数に同じ。
#             このオプションが使用される場合、第二引数は無視される。
#
# [使用例]
#   $ ruby yaml_reader.rb planes.yml f-14,engine,output
#   5,600 kgf
#   
#   $ cat planes.yml | ruby yaml_reader.rb -k f-14,engine,output -k f/a-18,nickname
#   5,600 kgf
#   Hornet

require 'yaml'
require 'optparse'

def main
  keies = []
  yaml_doc = nil
  
  # オプションの処理
  opt = OptionParser.new
  opt.on('-k KEY1,KEY2,...') {|v| keies.push v.split(",") }
  opt.parse!(ARGV)
  
  if pipe? || redirect?
    # パイプかリダイレクトの場合
    # YAML読み込み
    yaml_doc = STDIN.read
    # -k オプションが指定されていなければ引数から検索キーを取得する
    keies = [ ARGV[0].split(",") ] if keies.empty?
  else
    # パイプ、リダイレクトでない場合
    # YAML読み込み
    filepath = ARGV[0]
    open( filepath, "rb" ) do | io |
      yaml_doc = io.read
    end
    # -k オプションが指定されていなければ引数から検索キーを取得する
    if keies.empty?
      ARGV.shift
      keies = [ ARGV[0].split(",") ]
    end
  end
  
  # YAMLドキュメント読み込み
  data = YAML.load( yaml_doc )
  
  # キーの数だけ繰り返す
  keies.each do | key_list |
    # 繰り返し用変数の初期化
    itr = data
    
    key_list.each do | key |
      # 現在の値がnilの場合は繰り返しを終了する
      break if itr.class == NilClass
      # 現在の値が配列の場合はキーを数値に変換する
      key = key.to_i if itr.class == Array
      
      itr = itr[key]
    end
    
    # 結果の表示
    puts itr
  end
  
  # puts result if result
end

def pipe?
  File.pipe? STDIN
end

def redirect?
  File.select( [STDIN], [], [], 0 ) != nil
end

main
