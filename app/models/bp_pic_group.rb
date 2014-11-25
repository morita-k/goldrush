# -*- encoding: utf-8 -*-
require 'auto_type_name'
class BpPicGroup < ActiveRecord::Base
  include AutoTypeName
  has_many :bp_pic_group_details, :conditions => "bp_pic_group_details.deleted = 0"
  attr_accessible :owner_id, :bp_pic_group_name, :memo, :lock_version, :mail_template_id, :matching_way_type

  validates_presence_of :bp_pic_group_name
  validates_uniqueness_of :bp_pic_group_name, :case_sensitive => false, :scope => [:owner_id, :deleted, :deleted_at]
  before_save :set_default

  def set_default
    self.matching_way_type ||= 'other'
  end

  def detail_count
    BpPicGroupDetail.where(:owner_id => owner_id, :bp_pic_group_id => id, :deleted => 0).count
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
    details = BpPicGroupDetail.where(owner_id: owner_id, bp_pic_group_id: source_group_id, deleted: 0)
    details.each do |detail|
      clone = BpPicGroupDetail.new(
        owner_id: self.owner_id,
        bp_pic_group_id: self.id,
        bp_pic_id: detail.bp_pic_id,
        suspended: detail.suspended,
        memo: detail.memo
      )
      clone.save!
    end
  end

  # [[bp_pic_group_name, id]]
  def BpPicGroup.available_group_list(owner_id)
    BpPicGroup.where(owner_id: owner_id, deleted: 0).map {|group| [group.bp_pic_group_name, group.id]}
  end

end
