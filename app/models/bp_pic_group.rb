# -*- encoding: utf-8 -*-
class BpPicGroup < ActiveRecord::Base
  has_many :bp_pic_group_details, :conditions => "bp_pic_group_details.deleted = 0"
  attr_accessible :bp_pic_group_name, :memo, :lock_version
  
  validates_presence_of :bp_pic_group_name
  validates_uniqueness_of :bp_pic_group_name, :case_sensitive => false, :scope => [:deleted, :deleted_at]

  def detail_count
    BpPicGroupDetail.where(:bp_pic_group_id => id, :deleted => 0).count
  end

  def counted_group_name
    "#{bp_pic_group_name}(#{detail_count})"
  end
  
  def add_copy_string
    unless self.bp_pic_group_name =~ /.+(のコピー)$/
      self.bp_pic_group_name += "のコピー"
    end
  end
  
  def create_clone_group(source_group_id)
    details = BpPicGroupDetail.where(bp_pic_group_id: source_group_id, deleted: 0)
    details.each do |detail|
      clone = BpPicGroupDetail.new(
        bp_pic_group_id: self.id,
        bp_pic_id: detail.bp_pic_id,
        suspended: detail.suspended,
        memo: detail.memo
      )
      clone.save!
    end
  end
  
  # [[bp_pic_group_name, id]]
  def BpPicGroup.available_group_list
    BpPicGroup.where(deleted: 0).map {|group| [group.bp_pic_group_name, group.id]}
  end
  
end
