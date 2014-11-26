# encoding: UTF-8
source 'https://rubygems.org'

gem 'rails', '3.2.13'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

# How to install for win32
# DevKitをインストール
# mysql-connectgorをダウンロードして展開。展開先を指定
# gem install mysql2 -- '--with-mysql-dir="C:\home\tools\mysql-connector-c-6.1.3-win32"'
# bundle install
# rubyのbinの下にlibmysql.dllをコピー
gem 'mysql2', '0.3.15'

gem 'json'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  #gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', '= 0.10.2', :platforms => :ruby
  gem "less-rails"
  gem 'twitter-bootstrap-rails', :git => 'git://github.com/seyhunak/twitter-bootstrap-rails.git', :branch => 'bootstrap3'

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug'
#
gem 'devise', '3.0.3'

gem 'dynamic_form', :git => 'git://github.com/rails/dynamic_form.git'

#gem 'tlsmail'

gem 'gettext_i18n_rails'
gem 'gettext', '>=1.9.3', :require => false, :group => :development
gem 'ruby_parser', :require => false, :group => :development

gem 'kaminari'

gem 'mail', '2.5.3'

# How to install for win32
# DevKitをインストール
# ImageMagickをインストールしてインストール先を指定
# gem install rmagick -v '2.13.2' -- '--platform=ruby --with-opt-dir="C:\Program Files (x86)\ImageMagick-6.8.6-Q16"'
# bundle install
gem 'rmagick', :require => 'RMagick'

group :development do
  # http://qiita.com/yusabana/items/8ce54577d959bb085b37
  gem 'better_errors', '~> 1.1.0'
  gem 'binding_of_caller'
  gem 'hirb'
  gem 'hirb-unicode'
  gem 'pry-rails'
#  gem 'pry-debugger'

  # renderファイル名をhtmlソース内にコメント表示
  gem 'rails_view_annotator'
end

group :test do
  gem 'simplecov', :require => false
  gem 'simplecov-rcov', :require => false
  gem "rspec", '2.14.1'
  gem "rspec-rails"
  gem "factory_girl_rails", "~> 3.0"
  gem "database_cleaner"
  gem "spring"
  gem "spring-commands-rspec"
  gem "guard-rspec"
  gem 'guard-spring'
  gem "rb-fsevent", :require => false
  gem "terminal-notifier-guard"
end

gem 'rb-readline'

gem 'dkim', :git => 'git://github.com/jhawthorn/dkim.git'
