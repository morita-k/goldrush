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
  def get_next_imm_status_types(current_status)
    case current_status
    when 'open'           then ['candidate']
    when 'candidate'      then ['down_approach',  'self_reject']
    when 'down_approach'  then ['upper_approach', 'down_reject']
    when 'upper_approach' then ['interview',      'upper_reject']
    when 'interview'      then ['contract',       'interview_reject']
    else                       []
    end
  end

  def next_imm_status_tag_list
    get_next_imm_status_types(@import_mail_match.imm_status_type).collect do |next_status|
      link_to("#{getLongType(:imm_status_type, next_status)}へ変更する",
              imm_change_status_path(:id => @import_mail_match.id, :next_status => next_status),
              {:class => "btn btn-info btn-midium"})
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
end
