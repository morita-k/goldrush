# -*- encoding: utf-8 -*-
class ContractTerm < ActiveRecord::Base
  include AutoTypeName

  has_many :approaches, :conditions => ["approaches.deleted = 0"]
  
  validates_presence_of     :payment, :contract_start_date, :contract_end_date

  def cutoff_and_sight
    "#{cutoff_date_type_name}締め#{payment_sight_type_name}払い"
  end

  def term_term
    "#{contract_start_date} ～ #{contract_end_date}"
  end

  def contract_renewal
    "#{contract_renewal_unit}(#{contract_renewal_terms})"
  end

  def payment_view=(x)
    self.payment = x.to_f * 10000
  end
  
  def payment_view
    payment / 10000.0
  end
  
  def payment_diff(other)
    (payment - other.payment)
  end
  
end
