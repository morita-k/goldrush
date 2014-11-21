# -*- encoding: utf-8 -*-
require 'test_helper'

class BpPicGroupsControllerOwnerTest < ActionController::TestCase
  setup do
    @controller = BpPicGroupsController.new
    login_user = users(:users_16)
    sign_in login_user
    @owner_id = login_user.owner_id
    @bp_pic_group = bp_pic_groups(:bp_pic_groups_2)
    request.env['REQUEST_URI'] = ""
  end

  test "should get index" do
  	current_owner_bp_pic_groups = BpPicGroup.where(:owner_id => @owner_id)

    get :index
    bp_pic_groups = assigns(:bp_pic_groups).select {|bp_pic_group| bp_pic_group.owner_id == @owner_id}
    assert_equal(current_owner_bp_pic_groups.size, bp_pic_groups.size)
    assert_response :success
  end

  test "should show bp_pic_group" do
    get :show, id: @bp_pic_group
    bp_pic_group_details = assigns(:bp_pic_group_details)
    assert_equal(bp_pic_group_details.count, bp_pic_group_details.select {|d| d.owner_id == @owner_id}.size)
    assert_response :success
  end

  test "should show bp_pic_group with delivery_mail_id" do
    get :show, id: @bp_pic_group, delivery_mail_id: DeliveryMail.where(:owner_id => @owner_id).first

    bp_pic_group_details = assigns(:bp_pic_group_details)
    delivery_mail = assigns(:delivery_mail)
    attachment_files = assigns(:attachment_files)

    assert_equal(bp_pic_group_details.count, bp_pic_group_details.select {|d| d.owner_id == @owner_id}.size)
    assert_equal(@owner_id, delivery_mail.owner_id)
    assert_equal(attachment_files.count, attachment_files.select {|af| af.owner_id == @owner_id}.size)
    assert_response :success
  end

  test "should create bp_pic_group" do
    assert_difference("BpPicGroup.where(:owner_id => #{@owner_id}).count", +1) do
      post :create, bp_pic_group: { bp_pic_group_name: "my test group#{@bp_pic_group.bp_pic_group_name}", matching_way_type: "bp_member", mail_template_id: '2', memo: "my test group memo" }, id: @bp_pic_group.id, back_to: "/bp_pic_groups"
    end

    assert_redirected_to "/bp_pic_groups"
  end

  test "should copy(create) bp_pic_group" do
    detail_count = BpPicGroupDetail.where(:bp_pic_group_id => @bp_pic_group.id).count

    assert_difference("BpPicGroup.where(:owner_id => #{@owner_id}).count", +1) do
      assert_difference("BpPicGroupDetail.where(:owner_id => #{@owner_id}).count", detail_count) do

        post :create, src_id: 2, bp_pic_group: { bp_pic_group_name: @bp_pic_group.add_copy_string, matching_way_type: "bp_member", memo: "my test group memo" }, id: @bp_pic_group.id, back_to: "/bp_pic_groups"

      end
    end

    assert_match(/のコピー/, @bp_pic_group.bp_pic_group_name)
    assert_redirected_to "/bp_pic_groups"
  end

  test "should get index by another owner" do
    sign_in users(:users_1)
    get :index
    bp_pic_groups = assigns(:bp_pic_groups).select {|bp_pic_group| bp_pic_group.owner_id == @owner_id}
    assert_empty(bp_pic_groups)
    assert_response :success
  end
end

