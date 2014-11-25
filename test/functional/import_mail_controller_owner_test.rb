# -*- encoding: utf-8 -*-
require 'test_helper'

class ImportMailControllerOwnerTest < ActionController::TestCase
  setup do
    @controller = ImportMailController.new
    login_user = users(:users_16)
    sign_in login_user
    @owner_id = login_user.owner_id
    @import_mail = import_mails(:import_mails_7)
    request.env['REQUEST_URI'] = ""
  end

  test "should get index" do
  	current_owner_import_mails = ImportMail.where(:owner_id => @owner_id)

    get :index
    import_mails = assigns(:import_mails).select {|im| im.owner_id == @owner_id}
    assert_equal(current_owner_import_mails.size, import_mails.size)
    assert_response :success
  end

  test "should get index by another owner" do
    sign_in users(:users_1)

    get :index
    import_mails = assigns(:import_mails).select {|im| im.owner_id == @owner_id}
    assert_empty(import_mails)
    assert_response :success
  end
end
