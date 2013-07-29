# -*- encoding: utf-8 -*-
module BusinessPartnerHelper
  
  def get_basic_contract_status_type_text(bp)
    if [:non_correspondence, :in_progress, :concluded].include?(bp.basic_contract_status_type.to_sym)
      return h(bp.basic_contract_status_type_name)
    else
      return ""
    end
  end
  
  def get_nda_status_type_text(bp)
    if [:non_correspondence, :in_progress, :concluded].include?(bp.nda_status_type.to_sym)
      return h(bp.nda_status_type_name)
    else
      return ""
    end
  end
  
end
