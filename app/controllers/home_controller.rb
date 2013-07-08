# -*- encoding: utf-8 -*-
class HomeController < ApplicationController

  def index
#    @calendar = true
    @announcement = Announcement.get_my_home_announce
    #current_month = BaseMonth.get_base_month_by_date
    #last_month = current_month.last_month
    
    #申請
    @monthly_application_count = BaseApplication.count(
      :include => [ :monthly_working ],
      :conditions => ["base_applications.deleted = 0 and base_applications.user_id = ? and base_applications.approval_status_type <> ? and base_applications.approval_status_type <> ? and base_applications.application_type in (?)", current_user.id, 'canceled', 'fixed', BaseApplication.monthly_application_typs])
    @weekly_application_count = BaseApplication.count(
      :include => [ :weekly_report ],
      :conditions => ["base_applications.deleted = 0 and base_applications.user_id = ? and base_applications.approval_status_type <> ? and base_applications.approval_status_type <> ? and base_applications.application_type in (?)", current_user.id, 'canceled', 'fixed', BaseApplication.weekly_application_typs])
    @working_application_count = BaseApplication.count(
      :include => [ :other_application, :business_trip_application, :holiday_application ],
      :conditions => ["base_applications.deleted = 0 and base_applications.user_id = ? and base_applications.approval_status_type <> ? and base_applications.approval_status_type <> ? and base_applications.application_type in (?)", current_user.id, 'canceled', 'fixed', BaseApplication.working_application_typs])
#    @expense_application_count = BaseApplication.count(
#      :include => [ :expense_application, :payment_per_month, :payment_per_case ],
#      :conditions => ["base_applications.deleted = 0 and base_applications.user_id = ? and base_applications.approval_status_type <> ? and base_applications.approval_status_type <> ? and base_applications.application_type in (?)", current_user.id, 'canceled', 'fixed', BaseApplication.expense_application_typs])
    @expense_application_count = BaseApplication.count(
      :include => [ :expense_application],
      :conditions => ["base_applications.deleted = 0 and base_applications.user_id = ? and base_applications.approval_status_type <> ? and base_applications.approval_status_type <> ? and expense_applications.expense_app_type in (?)", current_user.id, 'canceled', 'fixed', ['expense_account_app','meeting_expenses_app','material_expenses_app']])

    #承認
    @monthly_approval_count = BaseApplication.count(
      :include => [:application_approvals, :monthly_working],
      :conditions => ["base_applications.deleted = 0 and application_approvals.approver_id = ? and base_applications.approval_status_type in (?) and application_approvals.approval_status_type in (?) and base_applications.application_type in (?)", current_user.id, ['entry','retry','approved'], ['entry','retry'], BaseApplication.monthly_application_typs])
    @weekly_approval_count = BaseApplication.count(
      :include => [:application_approvals, :weekly_report],
      :conditions => ["base_applications.deleted = 0 and application_approvals.approver_id = ? and base_applications.approval_status_type in (?) and application_approvals.approval_status_type in (?) and base_applications.application_type in (?)", current_user.id, ['entry','retry','approved'], ['entry','retry'], BaseApplication.weekly_application_typs])
    @working_approval_count = BaseApplication.count(
      :include => [:application_approvals, :other_application, :business_trip_application, :holiday_application],
      :conditions => ["base_applications.deleted = 0 and application_approvals.approver_id = ? and base_applications.approval_status_type in (?) and application_approvals.approval_status_type in (?) and base_applications.application_type in (?)", current_user.id, ['entry','retry','approved'], ['entry','retry'], BaseApplication.working_application_typs])
#    @expense_approval_count = BaseApplication.count(
#     :include => [:application_approvals, :expense_application, :payment_per_month, :payment_per_case],
#     :conditions => ["base_applications.deleted = 0 and application_approvals.approver_id = ? and application_approvals.approval_status_type <> ? and application_approvals.approval_status_type <> ? and base_applications.application_type in (?)", current_user.id, 'canceled', 'fixed', BaseApplication.expense_application_typs])
    @expense_approval_count = BaseApplication.count(
      :include => [:application_approvals, :expense_application],
      :conditions => ["base_applications.deleted = 0 and application_approvals.approver_id = ? and base_applications.approval_status_type in (?) and application_approvals.approval_status_type in (?) and base_applications.application_type in (?)", current_user.id, ['entry','retry','approved'], ['entry','retry'], BaseApplication.expense_application_typs])
  end

  def announcement
    @announcement = Announcement.get_my_home_announce
    if request.post?
      @announcement.attributes = params[:announcement]
      set_user_column @announcement
      @announcement.save!
      flash[:notice] = "おしらせメッセージが更新されました"
    end
  rescue ActiveRecord::RecordInvalid
  end

  def stale_object
  end
  
  def change_star
    model = params[:model].constantize.find(params[:id])
    # 0 -> 1 -> 2 -> 0と遷移
    model.starred = (model.starred + 1) % 3
    set_user_column model
    model.save!
    color = SysConfig.star_color[model.starred]
    respond_to do |format|
      format.js {render :text => <<EOS
var l = $('.starred_icon_#{model.id}');
for(var i = 0; i < l.length + 1; i++){
  l[i].style.color = '#{color}';
}
EOS
}
    end
  end
end
