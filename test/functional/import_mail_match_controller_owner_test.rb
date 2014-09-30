# -*- encoding: utf-8 -*-
require 'test_helper'

class ImportMailMatchControllerOwnerTest < ActionController::TestCase
  setup do
    @controller = ImportMailMatchController.new
    login_user = users(:users_16)
    sign_in login_user
    @owner_id = login_user.owner_id
    @import_mail_matches = import_mail_matches(:import_mail_matches_4)
    request.env['REQUEST_URI'] = ""
  end

  test "should get index" do
  	current_owner_import_mail_matches = ImportMailMatch.where(:owner_id => @owner_id)

    get :index
    import_mail_matches = assigns(:import_mail_matches).select {|imm| imm.owner_id == @owner_id}
    assert_equal(current_owner_import_mail_matches.size, import_mail_matches.size)
    assert_response :success
  end

  test "should get index by another owner" do
    sign_in users(:users_1)

    get :index
    import_mail_matches = assigns(:import_mail_matches).select {|imm| imm.owner_id == @owner_id}
    assert_empty(import_mail_matches)
    assert_response :success
  end
end
