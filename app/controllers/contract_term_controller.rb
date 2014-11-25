# -*- encoding: utf-8 -*-
class ContractTermController < ApplicationController

  def index
    list
    render :action => 'list'
  end



  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @contract_term_pages, @contract_terms = paginate :contract_terms, :conditions =>["deleted = 0"], :per => current_user.per_page
  end

  def show
    @contract_term = ContractTerm.find(params[:id])
  end

  def new
    @contract_term = ContractTerm.new
  end

  def create
    @contract_term = create_model(:contract_terms, params[:contract_term])
    set_user_column @contract_term
    @contract_term.save!
    flash[:notice] = 'ContractTerm was successfully created.'
    redirect_to :action => 'list'
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  def edit
    @contract_term = ContractTerm.find(params[:id])
  end

  def update
    @contract_term = ContractTerm.find(params[:id], :conditions =>["deleted = 0"])
    @contract_term.attributes = params[:contract_term]
    set_user_column @contract_term
    @contract_term.save!
    flash[:notice] = 'ContractTerm was successfully updated.'
    redirect_to :action => 'show', :id => @contract_term
  rescue ActiveRecord::RecordInvalid
    render :action => 'edit'
  end

  def destroy
    @contract_term = ContractTerm.find(params[:id], :conditions =>["deleted = 0"])
    @contract_term.deleted = 9
    @contract_term.deleted_at = Time.now
    set_user_column @contract_term
    @contract_term.save!
    
    redirect_to :action => 'list'
  end
end
