# -*- encoding: utf-8 -*-
class AttachmentFileController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def create
    upfile = params[:upfile]
    
    if upfile.blank?
      flash[:notice] = 'ファイルを選択してください'
      redirect_to params[:back_to]
      return
    end
    
    Contract.transaction do
      attachment_file = create_model(:attachment_files)
      attachment_file.create_and_store!(upfile, params[:parent_id], upfile.original_filename, params[:parent_table], current_user.login)
    end
    
    flash[:notice] = 'AttachmentFile was successfully uploaded.'
    redirect_to params[:back_to]
  rescue ActiveRecord::RecordInvalid
    render :controller => params[:parent_table], :action => 'show', :id => params[:parent_id]
  end

  def destroy
    attachment_file = AttachmentFile.find(params[:id], :conditions =>["deleted = 0"])
    bp_member_id = attachment_file.parent_id
    attachment_file.deleted = 9
    attachment_file.deleted_at = Time.now
    set_user_column attachment_file
    attachment_file.save!

    redirect_to back_to
  end

  def download
    attachment_file = AttachmentFile.find(params[:id], :conditions =>["deleted = 0"])
    send_file(attachment_file.file_path, :filename => attachment_file.file_name)
  end

end
