# -*- encoding: utf-8 -*-
class TagJournal < ActiveRecord::Base
  belongs_to :tag
  def TagJournal.put_journal!(tag_id, adjust)
    tj = TagJournal.new
    tj.tag_id = tag_id
    tj.adjust = adjust
    tj.opened = 1
    tj.summary_status_type = 'new'
#    tj.created_user = self.updated_user
#    tj.updated_user = self.updated_user
    tj.save!
  end

  def TagJournal.summry_tags!
    fetch_key = "summry_tags " + Time.now.to_s + " " + rand().to_s
    # 他のプロセスと更新がかぶらないようにする
    TagJournal.update_all("summary_status_type = 'fetched', updated_user = '#{fetch_key}' ", "summary_status_type = 'new'")
    
    ActiveRecord::Base.transaction do
      proc_count = 0
      # 個別集計(ユーザ／タグ別)
      journals = TagJournal.find(:all , 
                   :select => "tag_id, sum(adjust) sum_adj, max(updated_at) max_updated_at",
                   :conditions => ["summary_status_type = 'fetched' and updated_user = ?", fetch_key],
                   :group => "tag_id")
      logger.info "CLUB SUMMARY Fetch #{journals.size} records."
      journals.each{|x|
        t = Tag.find(x.tag_id, :conditions => "deleted = 0")
        t.tag_count = t.tag_count.to_i + x.sum_adj.to_i
        t.inc_count = x.sum_adj.to_i
        t.display_order1 = (x.sum_adj.to_i > 0 ? x.max_updated_at.to_time.to_i : t.display_order1)
        t.updated_user = fetch_key
        t.save!
        proc_count += 1
      }
      logger.info "SUMMARY Proc #{proc_count} records."

      # ジャーナルを処理済みにする
      TagJournal.update_all("summary_status_type = 'closed', updated_user = '#{fetch_key}' ", "summary_status_type = 'fetched'")
    end # commit transaction
  end
end
