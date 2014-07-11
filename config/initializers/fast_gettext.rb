FastGettext.add_text_domain 'gxt', :path => 'locale', :type => :po
FastGettext.default_available_locales = ['en','de','ja'] #all you want to allow
FastGettext.default_locale = 'ja'
FastGettext.default_text_domain = 'gxt'
