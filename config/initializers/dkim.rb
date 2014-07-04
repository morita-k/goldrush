#Dkim::domain      = 'applicative.co.jp'
Dkim::domain      = 'gr.applicative.jp'
Dkim::identity    = 'error@gr.applicative.jp'
Dkim::selector    = 'default'
Dkim::private_key = open('config/applicative.co.jp.dkim.key').read
ActionMailer::Base.register_interceptor(Dkim::Interceptor)

#Dkim::signable_headers  = Dkim::DefaultHeaders + %w{Return-Path}

