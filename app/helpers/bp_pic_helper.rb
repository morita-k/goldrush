# -*- encoding: utf-8 -*-
module BpPicHelper

  def search_value(code)
    session[:bp_pic_search] && session[:bp_pic_search][code]
  end

end
