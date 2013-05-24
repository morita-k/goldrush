# -*- encoding: utf-8 -*-
class Tag < ActiveRecord::Base
  has_many :tag_details, :conditions => ["tag_details.deleted = 0"]
  has_many :tag_journals, :conditions => ["tag_journals.deleted = 0"]
  
  before_save :clear_tag_cache
  
  def clear_tag_cache
    Tag.clear_tag_cache
  end

  # タグの文字列を受け取って正規化する
  # 正規化=>小文字化、",",半角スペース、全角スペースで区切り、文字列の配列として戻す
  def Tag.normalize_tag(tag_string)
    return tag_string.to_s.downcase.split(",").delete_if{|x| x.blank? }.sort.uniq
  end

  def Tag.create_tags!(key, parent_id, tag_string)
    splited_tags = Tag.normalize_tag(tag_string)
    splited_tags.each do |tag_text|
      unless t = Tag.find(:first, :conditions => ["tag_text = ? and tag_key = ? and deleted = 0", tag_text, key])
        t = Tag.new
        t.tag_text = tag_text
        t.tag_key = key
#        t.created_user = self.updated_user
#        t.updated_user = self.updated_user
        t.save!
      end
      TagDetail.create_tags!(t.id, parent_id, tag_text, key)
      TagJournal.put_journal!(t.id, 1)
      # TODO: 利用者が少ないため、ここで集計しているが本来cronで定期的に集計する
      # 利用者が増えたら対応
    end
    #TagJournal.summry_tags!
  end

  def Tag.update_tags!(key, parent_id, tag_string)
     # 旧Tagに対する処理
    details = TagDetail.find(:all, :joins => :tag, :readonly => false, :conditions => ["tags.tag_key = ? and parent_id = ? and tags.deleted = 0 and tag_details.deleted = 0", key, parent_id])
    details.each do |detail|
      detail.deleted = 9
      detail.deleted_at = Time.now
#      deteled_user = '???'
      detail.save!
      TagJournal.put_journal!(detail.tag_id, -1)
    end
    Tag.create_tags!(key, parent_id, tag_string)
  end

  def Tag.delete_tags!(key, parent_id)
    Tag.update_tags!(key, parent_id, "")
  end
  
  def Tag.clear_tag_cache
    puts "clear"
    @@good_tags = nil
    @@bad_tags = nil
  end
  Tag.clear_tag_cache
  
  def Tag.good_tags
    @@good_tags || (@@good_tags = starred_tags(1))
  end

  def Tag.bad_tags
    @@bad_tags || (@@bad_tags = starred_tags(2))
  end

  def Tag.starred_tags(star)
    where(deleted: 0, tag_key: "import_mails", starred: star).map{|x| x.tag_text}
  end
end

