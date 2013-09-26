# -*- encoding: utf-8 -*-
module BusinessPartnerHelper
  
  def basic_contract_concluded_text(bp)
    raw(bp.basic_contract_concluded != "" ? " [<span style='font-weight:bold' title='基本契約締結済み'>" + bp.basic_contract_concluded + "</span>]" : "")
  end

  def get_basic_contract_first_party_status_type_text(bp)
    if [:non_correspondence, :in_progress, :concluded].include?(bp.basic_contract_first_party_status_type.to_sym)
      return h(bp.basic_contract_first_party_status_type_name)
    else
      return ""
    end
  end

  def get_basic_contract_second_party_status_type_text(bp)
    if [:non_correspondence, :in_progress, :concluded].include?(bp.basic_contract_second_party_status_type.to_sym)
      return h(bp.basic_contract_second_party_status_type_name)
    else
      return ""
    end
  end

  def photo_id_hidden_field
    if params[:photoid]
      hidden_field_tag :photoid, params[:photoid]
    else
      ''
    end
  end
end
