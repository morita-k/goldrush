# -*- encoding: utf-8 -*-
module OutflowMailHelper

  def getbusinesspartnername(business_partner_id)
    business_partner_id.nil? ? "" : BusinessPartner.find(business_partner_id).business_partner_name
  end

  def getbppicname(bp_pic_id)
    bp_pic_id.nil? ? "" : BpPic.find(bp_pic_id).bp_pic_name
  end

end