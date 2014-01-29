# -*- encoding: utf-8 -*-
class ContractTerm < ActiveRecord::Base
  include AutoTypeName

  has_many :approaches, :conditions => ["approaches.deleted = 0"]
  
#  validates_presence_of     :payment, :contract_start_date, :contract_end_date
  validates_presence_of     :payment

  def cutoff_and_sight
    "#{cutoff_date_type_name}締 #{payment_sight_type_name}払"
  end

  def payment_view=(x)
    self.payment = x.to_f * 10000
  end
  
  def payment_view
    payment / 10000.0
  end
  
  def tax_exclude?
    tax_type == 'exclude'
  end

  def payment_tax
    x = (tax_exclude? ? 1 : 1.05)
    payment / x
  end

  def payment_view_tax
    payment_tax / 10000.0
  end

  def payment_diff(other)
    (payment_tax - other.payment_tax)
  end
  
end
