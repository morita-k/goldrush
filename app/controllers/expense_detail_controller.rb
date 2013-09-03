# -*- encoding: utf-8 -*-
class ExpenseDetailController < ApplicationController

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update, :cutoff ],
         :redirect_to => { :action => :list }

  # リスト作成時の内部処理
  def set_list_info(base_month_id, target_user_id)
    @calendar = true
    if target_user_id
      @target_user = User.find(target_user_id, :conditions => "deleted = 0")
    else
      @target_user = current_user
    end

    if base_month_id
      @base_month = BaseMonth.find(base_month_id, :conditions => "deleted = 0")
    else
      if @payment_per_month = PaymentPerMonth.get_target_month(@target_user.id)
        @base_month = @payment_per_month.base_month
        return
      else
        @base_month = BaseMonth.get_base_month_by_date
      end
    end
    @payment_per_month = PaymentPerMonth.get_payment_per_month(@base_month, @target_user.id)
  end

  # 通常の経費精算一覧リスト
  def list
    set_list_info(params[:id], params[:user_id])
    @expense_details = @payment_per_month.expense_details
    @table_title = @payment_per_month.cutoff_end_date.to_date.strftime("%Y年%m月度 経費精算")
    render(:action => :print, :layout => false) if params[:print_mode]
  end

  # 会社カードの経費精算一覧リスト
  def card_list
    set_list_info(params[:id], params[:user_id])
    @expense_details = @payment_per_month.card_expense_details
    @table_title = @payment_per_month.cutoff_end_date.to_date.strftime("%Y年%m月度 経費精算") + "(会社カード分)"
    params[:print_mode] ? render(:action => :print, :layout => false) : render(:action => 'list')
  end

  # 全部表示の経費精算一覧リスト
  def all_list
    set_list_info(params[:id], params[:user_id])
    @expense_details = @payment_per_month.all_expense_details
    @table_title = @payment_per_month.cutoff_end_date.to_date.strftime("%Y年%m月度 経費精算") + "(全部)"
    params[:print_mode] ? render(:action => :print, :layout => false) : render(:action => 'list')
  end

  # 都度精算の経費精算一覧リスト
  def case_list
    @payment_per_case = PaymentPerCase.find(params[:id])
    @payment_per_month = @payment_per_case.payment_per_month

    set_list_info(@payment_per_month.base_month_id, params[:user_id])

    @expense_details = @payment_per_case.expense_details
    @table_title = @payment_per_month.cutoff_end_date.to_date.strftime("%Y年%m月%d日 申請分都度経費精算")
    params[:print_mode] ? render(:action => :print, :layout => false) : render(:action => 'list')
  end

  # 未使用 TODO: 削除
  def detail_list
    @expense_detail_pages, @expense_details = paginate(:expense_details, :per_page => 50, :conditions => ["user_id = ?", @target_user.id], :order => "id ")
  end

  # 未使用 TODO: 削除
  def show
    @expense_detail = ExpenseDetail.find(params[:id])
  end

  # 経費明細の追加／更新一覧画面表示処理
  def new
    @calendar = true

    set_list_info(params[:id], params[:user_id])

    if @payment_per_month.new_record?
      @expense_details = Array.new
    else
      # 都度精算申請中は、リストに含めない(編集できない)
      @expense_details = ExpenseDetail.find(:all, :conditions => ["deleted = 0 and user_id = ? and payment_per_month_id = ? and payment_per_case_id is null", @target_user.id, @payment_per_month.id], :order => "id ")
    end
    @new_expense_details = Array.new
    10.times do |i|
      @new_expense_details << ExpenseDetail.new
    end
  end

  # 経費明細の追加／更新処理
  def create
      parseCurrency(params)
      begin
        parseTimes(params)
      rescue
        flash[:err] = '日付項目に誤りがあります'
        redirect_to :action => 'new', :id => params[:id], :user_id => params[:user_id]
        return
      end
      
      set_list_info(params[:id], params[:user_id])
      if @payment_per_month.new_record?
        set_user_column @payment_per_month
        @payment_per_month.save!
      end
      @expense_details = Array.new
      input_error = false
      input_d8_error = false
      input_overd40_error = false
      input_overd4000_error = false
      input_book_no_errors = Array.new
      input_account_item_errors = Array.new
      params[:update_expense_detail_count].to_i.times do |i|
        next unless params["uexpense_detail#{i}"]
        d = ExpenseDetail.find(params["uexpense_detail#{i}"][:id])
        d.attributes = params["uexpense_detail#{i}"]
        d.temporary_flg = 1 if d.expense_type == 'temporary_expense'
        
        # 全部がブランクじゃなくて、一つでも掛けていたらエラー
        unless d.buy_date.blank? && d.book_no.blank? && d.account_item.blank? && d.content.blank? && d.amount.blank?
          if d.buy_date.blank? || d.book_no.blank? || d.account_item.blank? || d.content.blank? || d.amount.blank?
            input_error = true
          end
          if d.book_no.to_s.length != 8
            input_d8_error = true
          end
          if d.account_item.to_s.length > 40
            input_overd40_error = true
          end
          if d.content.to_s.length > 4000
            input_overd4000_error = true
          end
          if !TasseikunJobHeader.get_job(d.book_no)
            input_book_no_errors << d.book_no
          end
          if !TasseikunAccountTitle.get_title_name(d.account_item)
            input_account_item_errors << d.account_item
          end
        else
          # 編集モードで、全部ブランクだったら削除の扱い
          d.deleted = 9 
        end
        
        set_user_column d
        if params["uexpense_detail_delete_#{i}"]
          d.deleted = 9 
          d.save!
          flash[:notice] = '経費明細を削除しました'
          redirect_to :action => :new, :id =>  @base_month, :user_id => params[:user_id]
          return
        end
        @expense_details << d
      end
      
      @new_expense_details = Array.new
      #input_error = false
      #input_d8_error = false
      10.times do |i|
        x = ExpenseDetail.new(params["expense_detail#{i}"])
        x.expense_type = 'normal'
        x.payment_per_month_id = @payment_per_month.id
        x.user_id = @target_user.id
        x.cutoff_status_type = 'open'
        x.temporary_flg = 1 if x.expense_type == 'temporary_expense'
        # 全部がブランクじゃなくて、一つでも掛けていたらエラー
        unless x.buy_date.blank? && x.book_no.blank? && x.account_item.blank? && x.content.blank? && x.amount.blank?
          if x.buy_date.blank? || x.book_no.blank? || x.account_item.blank? || x.content.blank? || x.amount.blank?
            input_error = true
          end
          if x.book_no.to_s.length != 8
            input_d8_error = true
          end
          if x.account_item.to_s.length > 40
            input_overd40_error = true
          end
          if x.content.to_s.length > 4000
            input_overd4000_error = true
          end
          if !TasseikunJobHeader.get_job(x.book_no)
            input_book_no_errors << x.book_no
          end
          if !TasseikunAccountTitle.get_title_name(x.account_item)
            input_account_item_errors << x.account_item
          end
        end
        set_user_column x
        @new_expense_details << x
      end

      set_user_column @payment_per_month

      if input_error
        flash[:err] = '全項目が入力されていない明細があります'
        render :action => 'new', :id => @base_month, :user_id => params[:user_id]
        return
      end
      if input_d8_error
        flash[:err] = '8桁で受注Noを入力してください'
        render :action => 'new', :id => @base_month, :user_id => params[:user_id]
        return
      end
      if input_overd40_error
        flash[:err] = '科目Noは40文字以内で入力してください'
        render :action => 'new', :id => @base_month, :user_id => params[:user_id]
        return
      end
      if input_overd4000_error
        flash[:err] = '内容は4000文字以内で入力してください'
        render :action => 'new', :id => @base_month, :user_id => params[:user_id]
        return
      end
      if !input_book_no_errors.empty?
        flash[:err] = "受注Noが存在しません(#{input_book_no_errors.join(',')})"
        render :action => 'new', :id => @base_month, :user_id => params[:user_id]
        return
      end
      if !input_account_item_errors.empty?
        flash[:err] = "科目Noが存在しません(#{input_account_item_errors.join(',')})"
        render :action => 'new', :id => @base_month, :user_id => params[:user_id]
        return
      end

    ActiveRecord::Base.transaction do
      @payment_per_month.save!
      @expense_details.each{|d| d.save!}
      @new_expense_details.each{|d|
        if d.buy_date.blank? && d.book_no.blank? && d.account_item.blank? && d.content.blank? && d.amount.blank?
          next
        end
        d.save!
      }
    end
    flash[:notice] = '経費明細を登録しました'
    redirect_to :action => 'new', :id => @base_month, :user_id => params[:user_id]
  rescue ActiveRecord::RecordInvalid
    render :action => 'new', :id => @base_month, :user_id => params[:user_id]
  end

  # 未使用 TODO: 削除
  def edit
    @calendar = true
    @expense_detail = ExpenseDetail.find(params[:id])
  end

  # 未使用 TODO: 削除
  def update
    parseTimes(params)
    @expense_detail = ExpenseDetail.find(params[:id])
    if @expense_detail.update_attributes(params[:expense_detail])
      flash[:notice] = 'ExpenseDetail was successfully updated.'
      redirect_to :action => 'show', :id => @expense_detail
    else
      render :action => 'edit'
    end
  end

  # 未使用 TODO: 削除
  def destroy
    ExpenseDetail.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  # 月締精算処理本体
  def cutoff
    ActiveRecord::Base.transaction do
      @payment_per_month.expense_paid_date = Time.now
      base_application = BaseApplication.new
      base_application.user_id = @target_user.id
      base_application.application_type = 'payment_per_month_app'
#      base_application.approval_status_type = 'entry'
      base_application.approval_status_type = 'fixed'
      base_application.application_date = @payment_per_month.expense_paid_date
      set_user_column base_application
      base_application.save!

      @payment_per_month.base_application_id = base_application.id
      set_user_column @payment_per_month
      @payment_per_month.save!
=begin
      #休暇申請での全て承認者を取る。
      approval_authorities = ApprovalAuthority.find(:all, :conditions => ["user_id = ? and approver_type = ? and active_flg = 1 and deleted = 0", @target_user.id, 'expense_xxx'])
      if approval_authorities.empty?
        raise ValidationAbort.new('承認者が一人も登録されていません。承認権限設定をしてください')
      end
      
      #申請に承認者を設定
      count = 0
      for approval_authority in approval_authorities
        count = count + 1
        application_approval = ApplicationApproval.new
        application_approval.user_id = approval_authority.user_id
        application_approval.base_application_id = base_application.id
        application_approval.application_type = 'payment_per_month_app'
        application_approval.application_date = @payment_per_month.expense_paid_date
        application_approval.approver_id = approval_authority.approver_id
        application_approval.approval_status_type = 'entry'
        application_approval.approval_order = count
        set_user_column application_approval
        application_approval.save!
      end
=end
#      today = Date.today
#      lastday = Date.new(today.year,today.month,-1)
#      plan_paid_date = lastday
#      7.times{|i|
#        if ![0,6].include?((lastday - i).wday)
#          plan_paid_date = (lastday - i)
#          break
#        end
#      }

      total_amount = 0
      temp_total_amount = 0
      @payment_per_month.expense_details.each do |detail|
        next if detail.cutoff_status_type != 'open'
        detail.cutoff_status_type = 'waiting'
        set_user_column detail
        detail.save!
        if detail.temporary_flg == 0
          total_amount += detail.amount
        else
          temp_total_amount += detail.amount
        end
#        TasseikunCost.export(detail, @target_user, @payment_per_month.expense_paid_date, plan_paid_date)
      end
      @payment_per_month.temporary_amount_total = temp_total_amount
      @payment_per_month.total_amount = total_amount
      @payment_per_month.cutoff_status_type = 'waiting'
      @payment_per_month.save!
    end
    flash[:notice] = "月締経費精算申請しました"
    return redirect_to :action => :list, :id => @base_month.next_month.id
  end

  # 都度精算処理本体
  def per_case
    ActiveRecord::Base.transaction do
      @payment_per_case = PaymentPerCase.new
      @payment_per_case.user_id = @target_user.id
      @payment_per_case.payment_per_month_id = @payment_per_month.id
      @payment_per_case.expense_paid_date = Time.now
      @payment_per_case.cutoff_status_type = 'waiting'

      base_application = BaseApplication.new
      base_application.user_id = @target_user.id
      base_application.application_type = 'payment_per_case_app'
#      base_application.approval_status_type = 'entry'
      base_application.approval_status_type = 'fixed'
      base_application.application_date = @payment_per_case.expense_paid_date
      set_user_column base_application
      base_application.save!

      @payment_per_case.base_application_id = base_application.id
      set_user_column @payment_per_case
      @payment_per_case.save!
=begin
      #休暇申請での全て承認者を取る。
      approval_authorities = ApprovalAuthority.find(:all, :conditions => ["user_id = ? and approver_type = ? and active_flg = 1 and deleted = 0", @target_user.id, 'expense_xxx'])
      if approval_authorities.empty?
        raise ValidationAbort.new('承認者が一人も登録されていません。承認権限設定をしてください')
      end
      
      #申請に承認者を設定
      count = 0
      for approval_authority in approval_authorities
        count = count + 1
        application_approval = ApplicationApproval.new
        application_approval.user_id = approval_authority.user_id
        application_approval.base_application_id = base_application.id
        application_approval.application_type = 'payment_per_case_app'
        application_approval.application_date = @payment_per_case.expense_paid_date
        application_approval.approver_id = approval_authority.approver_id
        application_approval.approval_status_type = 'entry'
        application_approval.approval_order = count
        set_user_column application_approval
        application_approval.save!
      end
=end
      total_amount = 0
      cnt = 0
      params[:rowCheck] && params[:rowCheck].each{|key,val|
        detail = ExpenseDetail.find(key)
        next if detail.cutoff_status_type != 'open'
        detail.payment_per_case = @payment_per_case
        detail.cutoff_status_type = 'waiting'
        set_user_column detail
        detail.save!
#        TasseikunCost.export(detail, @target_user, @payment_per_case.expense_paid_date, @payment_per_case.expense_paid_date)
        total_amount += detail.amount
        cnt += 1
      }
      if cnt == 0
        raise ValidationAbort.new('承認となる明細が一件もありませんでした')
      end
      @payment_per_case.total_amount = total_amount
      set_user_column @payment_per_case
      @payment_per_case.save!
    end
    flash[:notice] = "都度経費精算申請しました"
    return redirect_to(params[:back_to])
  end

  # 都度／月締め経費精算申請ボタン
  def payment
    set_list_info(params[:id], params[:user_id])
    if @payment_per_month.new_record?
      set_user_column @payment_per_month
      @payment_per_month.save!
#      flash[:err] = "対象の月締経費精算が存在しません"
#      return redirect_to(params[:back_to])
    end
    if @payment_per_month.cutoff_status_type != 'open'
      flash[:err] = "すでに月締経費精算申請されています"
      return redirect_to(params[:back_to])
    end
    if params[:cutoff]
      cutoff
    elsif params[:per_case]
      per_case
    else
      raise "Param error!"
    end
  rescue ValidationAbort
    flash[:warning] = $!
    return redirect_to(params[:back_to])
  end

  # 都度精算の経理承認
  def cutoff_case
    flg = params[:release] ? 'waiting' : 'closed'
    paid_date = nil
    begin
      if flg == 'closed'
        paid_date = params[:paid_date].to_date
        if BaseDate.is_holiday?(paid_date)
          flash[:err] = '支払日に土日祝日は指定できません'
          redirect_to params[:back_to]
          return
        end
      end
    rescue
      flash[:err] = '支払日が正しくありません'
      redirect_to params[:back_to]
      return
    end
    ActiveRecord::Base::transaction() do
      payment_per_case = PaymentPerCase.find(params[:id], :conditions => "deleted = 0")
      payment_per_case.cutoff_status_type = flg
      payment_per_case.payment_date = paid_date
      set_user_column payment_per_case
      payment_per_case.save!
      payment_per_case.expense_details.each do |detail|
        detail.cutoff_status_type = flg
        set_user_column detail
        detail.save!
        # たっせい君連携
        if flg == 'closed'
#          TasseikunCost.export(detail, payment_per_case.user, payment_per_case.expense_paid_date, payment_per_case.expense_paid_date)
          TasseikunCost.export(detail, payment_per_case.user, payment_per_case.payment_date, payment_per_case.payment_date)
        end
      end
      TasseikunCost.clear_cache
    end
    redirect_to params[:back_to]
  end

  # 月締精算の経理承認
  def cutoff_month
    flg = params[:release] ? 'waiting' : 'closed'
    paid_date = nil
    begin
      if flg == 'closed'
        paid_date = params[:paid_date].to_date
        if BaseDate.is_holiday?(paid_date)
          flash[:err] = '支払日に土日祝日は指定できません'
          redirect_to params[:back_to]
          return
        end
      end
    rescue
      flash[:err] = '支払日が正しくありません'
      redirect_to params[:back_to]
      return
    end
    ActiveRecord::Base::transaction() do
      payment_per_month = PaymentPerMonth.find(params[:id], :conditions => "deleted = 0")
      payment_per_month.cutoff_status_type = flg
      payment_per_month.expense_paid_date = paid_date
      set_user_column payment_per_month
      payment_per_month.save!
      plan_paid_date = payment_per_month.plan_paid_date
      payment_per_month.all_expense_details.each do |detail|
        next if detail.payment_per_case_id != nil
        detail.cutoff_status_type = flg
        set_user_column detail
        detail.save!
        # たっせい君連携
        if flg == 'closed'
#          TasseikunCost.export(detail, payment_per_month.user, payment_per_month.expense_paid_date, plan_paid_date)
          TasseikunCost.export(detail, payment_per_month.user, payment_per_month.expense_paid_date, payment_per_month.expense_paid_date)
        end
      end
      TasseikunCost.clear_cache
    end
    redirect_to params[:back_to]
  end

  # 科目コード一覧ポップアップ
  def titles
    @tag_prefix = params[:tag_prefix]
    @titles = TasseikunAccountTitle.get_titles
  end

  def excel_download
    mode = params[:mode]
    id = params[:id]
    unless ['month','case','card'].include?(mode)
      flash[:err] = 'EXCELダウンロードのパラメータが不正です(mode)'
      return redirect_to(:action => '/')
    end
    if id.blank? || id.to_i == 0
      flash[:err] = 'EXCELダウンロードのパラメータが不正です(id)'
      return redirect_to(:action => '/')
    end
    java_dir = File.join(Rails.root, 'java')
    tmp_dir = File.join(Rails.root, 'tmp', 'excel')
    xxx = rand(1000000).to_s
    filename = "expense_#{mode}_#{id}_#{Time.now.strftime('%Y%m%d%H%M%S')}.xls"
    tmp_filename = filename + "." + xxx
    sep = ENV["OS"] ? ";" : ":" # Windows or UNIX??
    class_path = ["#{java_dir}","#{java_dir}/lib/poi-2.5.1-final-20040804.jar","#{java_dir}/lib/ojdbc14.jar"].join(sep)
    # TODO : furukawa : たぶんRAILS_ENVは使えない
    host = ActiveRecord::Base.configurations[RAILS_ENV]['host']
    if host[0] == '/'[0] # hostの一文字目が'/'だったらUNIX SOCKETと判断
      host = 'localhost'
    end
    # TODO : furukawa : たぶんRAILS_ENVは使えない
    username = ActiveRecord::Base.configurations[RAILS_ENV]['username']
    # TODO : furukawa : たぶんRAILS_ENVは使えない
    password = ActiveRecord::Base.configurations[RAILS_ENV]['password']
    if password.blank?
      password = '\"\"'
    end
    # TODO : furukawa : たぶんRAILS_ENVは使えない
    database = ActiveRecord::Base.configurations[RAILS_ENV]['database']
    command = "java -classpath #{class_path} gd/Main #{mode} jdbc:oracle:thin:@#{host}:1521:#{database} #{username} #{password} #{id} #{java_dir}/template_expense_detail1.xls #{tmp_dir}/#{tmp_filename}"
    logger.debug(command)
    result = `#{command}`
      
    send_file "#{tmp_dir}/#{tmp_filename}", :type => 'application/xls', :disposition => 'attachment', :filename => filename
  end

end
