# encoding: utf-8
module ImportMailMatchHelper
  # open
  #   |-> candidate
  #         |-> self_reject(END)
  #         |-> down_approach
  #              |-> down_reject(END)
  #              |-> upper_approach
  #                    |-> upper_reject(END)
  #                    |-> interview
  #                          |-> interview_reject(END)
  #                          |-> contract(END)
  def get_next_imm_status_list(current_status)
    case current_status
    when 'open'           then ['candidate']
    when 'candidate'      then ['down_approach',  'self_reject',      'open']
    when 'down_approach'  then ['upper_approach', 'down_reject',      'open']
    when 'upper_approach' then ['interview',      'upper_reject',     'open']
    when 'interview'      then ['contract',       'interview_reject', 'open']
    else                       ['open']
    end
  end

  def next_imm_status_tag_list
    get_next_imm_status_list(@import_mail_match.imm_status_type).collect do |next_status|
      btn_str, btn_style =if next_status == 'open'
                             ["#{getLongType(:imm_status_type, next_status)}へ戻す", 'btn-warning']
                           else
                             ["#{getLongType(:imm_status_type, next_status)}へ変更する", 'btn-info']
                           end
      link_to(btn_str,
              imm_change_status_path(id: @import_mail_match.id, next_status: next_status),
              { class: "btn #{btn_style} btn-midium" })
    end
  end

  def imm_status_tag(imm_status_type, imm_status_name)
    label_type = case imm_status_type
                 when 'open'      then 'label label-default'
                 when 'candidate' then 'label label-warning'
                 when /.*_reject/ then 'label label-danger'
                 when 'contract'  then 'label label-success'
                 else                  'label label-primary'
                 end
    content_tag(:span, imm_status_name, {title: "ステータス", class: label_type})
  end

  def get_all_imm_status_list
    Type.get_config_list('imm_status_type')
  end

  def imm_status_check_box_tag(session)
    get_all_imm_status_list.collect do |imm_status|
      check_box_name = "imm_status_type[#{imm_status.type_key}]"
      content_tag(:label) do
        check_box_tag(check_box_name, 1, session[:imm_status_type] && session[:imm_status_type][imm_status.type_key].to_i == 1) + imm_status.long_name
      end
    end.join('&nbsp;')
  end
end
