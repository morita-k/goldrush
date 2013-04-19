# -*- encoding: utf-8 -*-
class BpMember < ActiveRecord::Base
  include AutoTypeName
  has_many :approaches, :conditions => ["approaches.deleted = 0"]
  has_many :attachment_files, :conditions => ["attachment_files.deleted = 0"]

  belongs_to :human_resource
  belongs_to :business_partner
  belongs_to :bp_pic
  belongs_to :import_mail

  def attachment?
    AttachmentFile.count(:conditions => ["deleted = 0 and parent_table_name = 'bp_members' and parent_id = ?", self]) > 0
  end
  
  def payment_min_view=(x)
    self.payment_min = x.to_f * 10000
  end
  
  def payment_min_view
    payment_min.nil? ? 0 : payment_min / 10000.0
  end
end
