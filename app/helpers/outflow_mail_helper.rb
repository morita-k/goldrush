# -*- encoding: utf-8 -*-
module OutflowMailHelper

  def getmailstatustypename(outflow_mail)
    if [:non_correspondence, :bad, :good, :unwanted].include?(outflow_mail.outflow_mail_status_type.to_sym)
      h(outflow_mail.outflow_mail_status_type_name)
    else
      ""
    end
  end

  def getbusinesspartnername(business_partner_id)
    BusinessPartner.find(business_partner_id).business_partner_name
  end

  def getbppicname(bp_pic_id)
    BpPic.find(bp_pic_id).bp_pic_name
  end
end