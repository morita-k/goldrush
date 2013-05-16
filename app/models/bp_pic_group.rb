class BpPicGroup < ActiveRecord::Base
  has_many :bp_pic_group_details, :conditions => "bp_pic_group_details.deleted = 0"
  attr_accessible :bp_pic_group_name, :memo, :lock_version
  
  validates_presence_of :bp_pic_group_name

  def detail_count
    BpPicGroupDetail.where(:bp_pic_group_id => id, :deleted => 0).count
  end

  def counted_group_name
    "#{bp_pic_group_name}(#{detail_count})"
  end

end
