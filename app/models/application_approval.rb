# -*- encoding: utf-8 -*-
class ApplicationApproval < ActiveRecord::Base

  include AutoTypeName
  
  belongs_to :user
  belongs_to :base_application
  belongs_to :approver, :class_name => 'User'
  has_one :comment, :conditions => "comments.deleted = 0"
  
  def ApplicationApproval.approval_action_str(approval_status_type)
    x = {'approved' => '承認', 'entry' => '解除', 'reject' => '却下', 'fixed' => '確定'}
    x[approval_status_type]
  end

  def ApplicationApproval.change_to_status(approval_status_type)
    x = {'entry' => ['approved','reject'], 'approved' => ['entry'], 'reject' => ['entry'], 'retry' => ['approved','reject']}
    x[approval_status_type]
  end

  # 対象者が、対象申請データの承認者かどうか
  def ApplicationApproval.application_approver?(application_model, approver_id)
    approver_type_map = {
      'expense_applications' => 'expense_xxx',
      'payment_per_cases' => 'expense_xxx',
      'payment_per_months' => 'expense_xxx',
      'weekly_reports' => 'report_xxx',
      'monthly_workings' => 'report_xxx',
      'holiday_applications' => 'working_xxx',
      'other_applications' => 'working_xxx',
      'business_trip_applications' => 'business_trip_xxx'}
    tname = application_model.class.name.tableize
    ApprovalAuthority.find(:first, :conditions => ["deleted = 0 and approver_type = '#{approver_type_map[tname]}' and user_id = ? and approver_id = ?", application_model.user_id, approver_id])
  end

  # 対象者あての申請が出ていたら取得
  def ApplicationApproval.application_approval(application_model, approver_id)
    ApplicationApproval.find(:first, :conditions => ["deleted = 0 and approver_id = ? and base_application_id = ?", approver_id, application_model.base_application_id])
  end


end
