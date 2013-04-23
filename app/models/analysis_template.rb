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
  #   インデントによって内容をまとめ、整形して出力する
  #
  def AnalysisTemplate.analyze(analysis_template_id, import_mail, models)#biz_offer, business
    AnalysisTemplate.analyze_content(analysis_template_id, import_mail.mail_body, models)
  end

  def AnalysisTemplate.analyze_content(analysis_template_id, content, models)
    items = AnalysisTemplateItem.find(:all, 
      :conditions => ["deleted = 0 and analysis_template_id = ?", analysis_template_id])
    mail_parser = MailParser.new(content)
    
    items.each{ |item|
      models.each{ |model|
        next unless model.class.name == item.target_table_name.classify
#            puts">>>>>>>>>>>>table_name  : "+model.class.name
#            puts">>>>>>>>>>>>column_name : "+at_item.target_column_name
#            puts">>>>>>>>>>>>value       : "+$1
        unless item.before_set_code.blank?
          eval <<-EOS
            def AnalysisTemplate.before_set(model, item, str)
              #{item.before_set_code}
            end
          EOS
          before_set(model, item, $1)
        end
        
        model.send("#{item.target_column_name}=", mail_parser.conditions_body(item.pattern))
        
        unless item.after_set_code.blank?
          eval <<-EOS
            def AnalysisTemplate.after_set(model, item, str)
              #{item.after_set_code}
            end
          EOS
          after_set(model, item, $1)
        end
      }
    }
  end

end

class AnalysisTemplate::MailParser
  def initialize(here_document)
    @mail_body_lines = here_document.split(/\n/).reject{ |line| line == ""}
    @indtent_pattern = [/\t/, /\s/, /　/]
  end
  
  def add_indent_pattern(pattern)
    @indtent_pattern.push(/#{regex_escape(pattern)}/)
    self
  end
  
  def conditions_body(conditions_key)
    key_pattern = /^#{regex_escape(conditions_key)}/
    body = ""
    conditions = []
    
    # インデントをもとに各項目をまとめる
    @mail_body_lines.each { |line|
      line_head = line[0, 1]
      if indent_judge(line_head)
        body +=  line.strip.gsub(/:|：/, "") + "\n"
      else
        conditions.push(body)
        body = line.strip + "\n"
      end
    }
    conditions.push(body) # ループで漏れる末端要素の追加
    conditions.reject!{ |c| c == "" }
    
    # scanメソッドが成功した場合、["項目名", "条件", "ゴミ"] な配列を得る
    # 失敗した場合は[]
    wrapped_conditions = conditions.map{ |c|
      c.scan(/(#{key_pattern})[\s　]*[:：]?[\s　]*?((:?.*\n)*)/)
    }.reject{ |c| c == []}
    
    # 一致した場合、複数改行及び改行直後の空白を一つの改行にまとめ、内容のみを返す
    wrapped_conditions.size != 0 ? 
      wrapped_conditions.shift.shift[1].gsub(/[\s　]*?\n+[\s　]*/, "\n") : ""
  end
  
  # ===== Private =====
  def indent_judge(str)
    @indtent_pattern.any?{ |regex| regex =~ str}
  end
  
  def regex_escape(str)
    str.gsub(/[\[\]]/, "[" => '\[', "]" => '\]')
  end
  
  private :indent_judge, :regex_escape
  
end