# -*- encoding: utf-8 -*-
require 'application_util'
class ExpenseApplication < ActiveRecord::Base
  include AutoTypeName
  include ApplicationUtil

  attr_accessor :sales_person

  has_many :expense_details
  has_many :application_approvals
  belongs_to :user
  belongs_to :base_application
  has_one :expense_detail

  validates_presence_of :account_item, :if => "expense_app_type == 'temporary_app'"
  validates_presence_of :approximate_amount, :if => "expense_app_type == 'temporary_app'"
  validates_presence_of :plan_buy_date, :if => "expense_app_type != 'material_expenses_app'"
  validates_presence_of :payment_no, :account_item, :payment_amount, :if => "expense_app_type == 'fee_expense_app'"

  validates_length_of :book_no, :is=>8, :allow_blank => false, :if => "expense_app_type == 'fee_expense_app'"
  validates_length_of :account_item, :maximum=>40, :allow_blank => true
  validates_length_of :purpose, :maximum=>4000, :allow_blank => true
  validates_length_of :content, :maximum=>4000, :allow_blank => true

#   def validate?
#       if self.plan_buy_date == nil or self.plan_buy_date == "" and self.expense_app_type == 'fee_expense_app'
#         errors.add("支払希望日")
#       end
#       if self.plan_buy_date == nil or self.plan_buy_date == "" and self.expense_app_type == 'meeting_expenses_app'
#         errors.add("会議予定日")
#       end
#       if self.plan_buy_date == nil or self.plan_buy_date == "" and self.expense_app_type == 'expense_account_app'
#         errors.add("利用日")
#       end
#       if self.plan_buy_date == nil or self.plan_buy_date == "" and self.expense_app_type == 'temporary_app'
#         errors.add("利用予定日")
#       end
#   end

  def total_payment
    payment_amount.to_i + withholding_tax.to_i
  end

  def temporary_app?
    temporary_app_flg == 1
  end

  def paymented?
    self.payment_flg == 1
  end

  def fee_expense_app?
    self.expense_app_type == 'fee_expense_app'
  end

  def want_approval?
    !['fee_expense_app','temporary_app'].include?(self.expense_app_type)
  end

  def set_business_trip_application(source)
    self.user_id = source.user_id
    self.base_application_id = source.base_application_id
    self.expense_app_type = 'business_trip_app'
    self.application_date = source.application_date
    self.plan_buy_date = source.start_date
    self.start_date = source.start_date
    self.end_date = source.end_date
    self.day_total = source.day_total
    self.book_no = source.book_no
    self.purpose = source.reason
    self.content = source.content
    self.client = source.client
    self.location = source.location
    self.approximate_amount = source.approximate_amount
    if self.new_record?
      self.temporary_app_flg = 0
      self.temporary_scrip_flg = 0
      self.payment_flg = 0
      self.app_status_type = 'open'
      self.created_user = source.created_user
    end
    self.updated_user = source.updated_user
  end

  def ExpenseApplication.expense_fields
    {
      'expense_account_app' => [
        {:prop => 'plan_buy_date', :label => '利用日', :field => 'date_field', :option => {}},
        {:prop => 'book_no', :label => nil, :field => 'text_field', :option => {}},
        {:prop => 'purpose', :label => nil, :field => 'text_field', :option => {:size => 60}},
        {:prop => 'content', :label => nil, :field => 'text_area', :option => {:size => '60x3'}},
        {:prop => 'approximate_amount', :label => nil, :field => 'currency_field', :option => {}},
      ],
      'meeting_expenses_app' => [
        {:prop => 'plan_buy_date', :label => '会議予定日', :field => 'date_field', :option => {}},
        {:prop => 'book_no', :label => nil, :field => 'text_field', :option => {}},
        {:prop => 'purpose', :label => nil, :field => 'text_field', :option => {:size => 60}},
        {:prop => 'content', :label => nil, :field => 'text_area', :option => {:size => '60x3'}},
        {:prop => 'approximate_amount', :label => nil, :field => 'currency_field', :option => {}},
      ],
      'material_expenses_app' => [
        {:prop => 'account_item', :label => nil, :field => 'text_field', :option => {:size => 10}},
        {:prop => 'purpose', :label => nil, :field => 'text_field', :option => {:size => 60}},
        {:prop => 'content', :label => '物品名', :field => 'text_area', :option => {:size => '60x3'}},
        {:prop => 'attached_material', :label => nil, :field => 'file_field', :option => {}},
        {:prop => 'approximate_amount', :label => nil, :field => 'currency_field', :option => {}},
      ],
      'fee_expense_app' => [
        {:prop => 'plan_buy_date', :label => '支払希望日', :field => 'date_field', :option => {}},
        {:prop => 'book_no', :label => nil, :field => 'text_field', :option => {}},
#        {:prop => 'sales_person_name', :label => '営業担当', :field => nil, :option => {}},
        {:prop => 'purpose', :label => nil, :field => 'text_field', :option => {:size => 60}},
        {:prop => 'content', :label => nil, :field => 'text_area', :option => {:size => '60x3'}},
        {:prop => 'payment_no', :label => nil, :field => 'text_field', :option => {:size => 8, :readonly => true, :style => "background-color: silver;"}},
        {:prop => 'payee_name', :label => nil, :field => 'text_field', :option => {:readonly => true, :style => "background-color: silver;"}},
        {:prop => 'payee_name_kana', :label => nil, :field => 'text_field', :option => {:readonly => true, :style => "background-color: silver;"}},
        {:prop => 'account_item', :label => nil, :field => 'text_field', :option => {:size => 10}},
        {:prop => 'payment_method_type', :label => nil, :field => 'select', :option => {}},
        {:prop => 'payment_amount', :label => nil, :field => 'currency_field', :option => {:onKeyDown => "if(event.keyCode == 13){$('calc_button').click();return false;}"}},
        {:prop => 'withholding_tax', :label => nil, :field => 'currency_field', :option => {}},
        {:prop => 'other_expenses', :label => nil, :field => 'currency_field', :option => {}},
        {:prop => 'approximate_amount', :label => '支払総額', :field => 'currency_field', :option => {}},
        {:prop => 'preferred_date', :label => nil, :field => 'date_field', :option => {}},
      ],
      'temporary_app' => [
        {:prop => 'plan_buy_date', :label => '利用予定日', :field => 'date_field', :option => {}},
        {:prop => 'preferred_date', :label => nil, :field => 'date_field', :option => {}},
        {:prop => 'account_item', :label => nil, :field => 'text_field', :option => {:size => 10}},
        {:prop => 'purpose', :label => nil, :field => 'text_field', :option => {:size => 60}},
        {:prop => 'content', :label => '内容', :field => 'text_area', :option => {:size => '60x3'}},
        {:prop => 'approximate_amount', :label => nil, :field => 'currency_field', :option => {}},
      ],
      'business_trip_app' => [
        {:prop => 'start_date', :label => nil, :field => 'date_field', :option => {}},
        {:prop => 'end_date', :label => nil, :field => 'date_field', :option => {}},
        {:prop => 'day_total', :label => nil, :field => 'text_field', :option => {}},
        {:prop => 'book_no', :label => nil, :field => 'text_field', :option => {}},
        {:prop => 'purpose', :label => nil, :field => 'text_field', :option => {:size => 60}},
        {:prop => 'content', :label => nil, :field => 'text_area', :option => {:size => '60x3'}},
        {:prop => 'client', :label => nil, :field => 'text_field', :option => {}},
        {:prop => 'location', :label => nil, :field => 'text_field', :option => {}},
        {:prop => 'approximate_amount', :label => nil, :field => 'currency_field', :option => {}},
      ],
    }
  end

  def sales_person_name
    x = Employee.find(:first, :conditions => ["user_id = ?", sales_person_id])
    x && x.employee_name
  end
  
  # 経費申請区分に応じた入力必須項目リストを返す
  def ExpenseApplication.required_item_list(type)
    required_items = case type
    when 'expense_account_app'
      ['payment_no']
    when 'meeting_expenses_app'
      ['payment_no']
    when 'fee_expense_app'
      ['payment_no', 'account_item', 'payment_amount', 'plan_buy_date', 'book_no']
    when 'temporary_app'
      ['account_item', 'approximate_amount', 'plan_buy_date']
    when 'business_trip_app'
      ['payment_no']
    else
      []
    end
  end
end
