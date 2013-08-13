# -*- encoding: utf-8 -*-
module BizOfferHelper
  
  def search_value_biz_offer(code)
    session[:biz_offer_search] && session[:biz_offer_search][code]
  end

end
