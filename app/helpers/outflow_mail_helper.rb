# -*- encoding: utf-8 -*-
module OutflowMailHelper

  def get_bp_name(business_partner_id)
    business_partner_id.nil? ? "" : BusinessPartner.find(business_partner_id).business_partner_name
  end

  def get_bp_pic_name(bp_pic_id)
    bp_pic_id.nil? ? "" : BpPic.find(bp_pic_id).bp_pic_name
  end

  def get_sales_pic_id(bp_pic)
  	bp_pic.nil? ? nil : bp_pic.sales_pic_id
  end

  def search_value_outflow_mail(code)
    session[:outflow_mail_search] && session[:outflow_mail_search][code]
  end

end