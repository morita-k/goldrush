# -*- encoding: utf-8 -*-
require 'test_helper'

class BusinessPartnerControllerOwnerTest < ActionController::TestCase
  setup do
    @controller = BusinessPartnerController.new
    login_user = users(:users_16)
    sign_in login_user
    @owner_id = login_user.owner_id
    @bp = business_partners(:business_partners_5)
    @bp_pic = bp_pics(:bp_pics_5)
    @bp_params = { business_partner_code: "xyz", business_partner_name: "test#{@bp.business_partner_name}", business_partner_short_name: @bp.business_partner_short_name, business_partner_name_kana: @bp.business_partner_name_kana, sales_status_type: 'listup' }
    @bp_pic_params = { bp_pic_name: "test#{@bp_pic.bp_pic_name}", bp_pic_short_name: @bp_pic.bp_pic_short_name, bp_pic_name_kana: @bp_pic.bp_pic_name_kana, email1: "test#{@bp_pic.email1}", working_status_type: 'working' }

    request.env['REQUEST_URI'] = ""
  end

  test "should get index" do
  	current_owner_bps = BusinessPartner.where(:owner_id => @owner_id)

    get :index
    bps = assigns(:business_partners).select {|bp| bp.owner_id == @owner_id}
    assert_equal(current_owner_bps.size, bps.size)
  end

  test "should create business_partner" do
    assert_difference("BusinessPartner.where(:owner_id => #{@owner_id}).count", +1) do
      assert_difference("BpPic.where(:owner_id => #{@owner_id}).count", +1) do
        post :create, business_partner: @bp_params, bp_pic: @bp_pic_params, back_to: "/business_partner"
      end
    end

    created_business_partner = BusinessPartner.order("id desc").first
    assert_redirected_to "/business_partner/show/#{created_business_partner.id}"
  end

  test "should create business_partner(from import mail)" do
    assert_no_difference("BusinessPartner.where(:owner_id => #{@owner_id}).count") do
      assert_difference("BpPic.where(:owner_id => #{@owner_id}).count", +1) do
        post :create, business_partner: @bp_params.merge({id: @bp.id}), bp_pic: @bp_pic_params, back_to: "/business_partner"
      end
    end

    assert_redirected_to "/business_partner/show/#{@bp.id}"
  end

  test "should get index by another owner" do
    sign_in users(:users_1)

    get :index
    bps = assigns(:business_partners).select {|bp| bp.owner_id == @owner_id}
    assert_empty(bps)
    assert_response :success
  end
end

