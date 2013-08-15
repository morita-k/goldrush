# -*- encoding: utf-8 -*-
module BpMemberHelper
  
  def search_value_bp_member(code)
    session[:bp_member_search] && session[:bp_member_search][code]
  end

end
