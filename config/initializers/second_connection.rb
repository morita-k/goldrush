
#データ退避用データベースに接続
unless conf = SecondConnection.configurations[conf_str = 'second_' + (ENV['RAILS_ENV'] || 'development').to_s]
  raise "error! #{conf_str} is not defined."
end
SecondConnection.establish_connection conf

