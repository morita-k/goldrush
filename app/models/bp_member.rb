# -*- encoding: utf-8 -*-
class BpMember < ActiveRecord::Base
  include AutoTypeName
  has_many :approaches, :conditions => ["approaches.deleted = 0"]
  has_many :attachment_files, :conditions => ["attachment_files.deleted = 0"]

  belongs_to :human_resource
  belongs_to :business_partner
  belongs_to :bp_pic
  belongs_to :import_mail

  validates_presence_of     :bp_pic_id
  validates_uniqueness_of   :bp_pic_id, :scope => [:human_resource_id]

  before_save :derive_business_partner

  def derive_business_partner
    if bp_pic
      if business_partner_id.blank? || business_partner_id != bp_pic.business_partner_id
        self.business_partner_id = bp_pic.business_partner_id
      end
    end
  end

  def human_resource_name
    human_resource.useful_name
  end

  def attachment?
    AttachmentFile.count(:conditions => ["deleted = 0 and parent_table_name = 'bp_members' and parent_id = ?", self]) > 0
  end
  
  # 内部での値の変換処理
  def convert!
    # [単価メモ]を[単価下限]に変換
    v = StringUtil.detect_payments_value(self.payment_memo).map{ |i| i.to_f }.min
    v *= 10000 if v
    self.payment_min = v
  end
  
  def payment_min_view=(x)
    self.payment_min = x.to_f * 10000
  end
  
  def payment_min_view
    payment_min.nil? ? 0 : payment_min / 10000.0
  end
end
