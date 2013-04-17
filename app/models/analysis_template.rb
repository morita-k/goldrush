# -*- encoding: utf-8 -*-
class AnalysisTemplate < ActiveRecord::Base
  include AutoTypeName

  validates_presence_of :analysis_template_name
  
  belongs_to :business_partner
  belongs_to :bp_pic
  has_many :analysis_template_items, :conditions => ["analysis_template_items.deleted = 0"]
  
  #
  # メール解析処理のメイン
  # 考え方:
  #   AnalysisTemplateItemより、対象のテンプレートを取得
  #   各項目をインデントによって分類しハッシュを生成、キーに対して正規表現マッチを行う。
  #
  def AnalysisTemplate.analyze(analysis_template_id, import_mail, models)#biz_offer, business
    
    items = AnalysisTemplateItem.find(:all, :conditions => ["deleted = 0 and analysis_template_id = ?", analysis_template_id])
    map = MailParser.new(import_mail.mail_body).classification_by_indent
    
    map.each { |k, v|
      items.each {|item|
        if k =~ Regexp.new(item.pattern)
          models.each do |model|
            next unless model.class.name == item.target_table_name.classify
  #            puts">>>>>>>>>>>>table_name  : "+model.class.name
  #            puts">>>>>>>>>>>>column_name : "+at_item.target_column_name
  #            puts">>>>>>>>>>>>value       : "+$1
            unless item.before_set_code.blank?
              eval <<-EOS
                def AnalysisTemplate.before_set(model, item, str)
                  #{at_item.before_set_code}
                end
              EOS
              before_set(model, item, $1)
            end

            model.send("#{item.target_column_name}=", v)

            unless item.after_set_code.blank?
              eval <<-EOS
                def AnalysisTemplate.after_set(model, item, str)
                  #{at_item.after_set_code}
                end
              EOS
              after_set(model, item, $1)
            end
            
          end # models.each
        end
      }
    }
  end

end


class AnalysisTemplate::MailParser

  def initialize(here_document)
    @mail_body_array = here_document.split(/\n/).reject!{ |line| line == ""}
  end
  
  def classification_by_indent
    working_conditions = []
    str = ""
    @mail_body_array.each {|s|
      s_head = s[0, 1]
      if /\t/ =~ s_head || /\s/ =~ s_head || /　/ =~ s_head
        str = str + s
      else
        working_conditions.push(str)
        str = s
      end
    }
    working_conditions.push(str) # ループで漏れる末端要素の追加
    working_conditions.reject!{ |t| t == ""}
    
    # Refactoring and Hashing
    hash = Hash.new
    working_conditions.each { |c|
      conditions_tag = c.split(/　|\s|:|：/)
      conditions_tag.reject!{ |t| t == "" || t == "　" || t == " " || t == ":" || t == "："}
      hash.store(conditions_tag.shift, conditions_tag.join("\n").lstrip)
    }
    hash
  end

end