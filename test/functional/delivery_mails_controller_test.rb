# -*- encoding: utf-8 -*-
require 'test_helper'

class DeliveryMailsControllerTest < ActionController::TestCase
  setup do
    sign_in users(:users_1)
    @delivery_mail = delivery_mails(:delivery_mails_1)
    request.env['REQUEST_URI'] = ""
  end

  test "should get index" do
    get :index, id: @delivery_mail
    assert_response :success
    assert_not_nil assigns(:delivery_mails)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create delivery_mail" do
    assert_difference('DeliveryMail.count') do
      post :create, delivery_mail: { bp_pic_group_id: @delivery_mail.bp_pic_group_id, content: @delivery_mail.content, mail_bcc: @delivery_mail.mail_bcc, mail_cc: @delivery_mail.mail_cc, mail_from: @delivery_mail.mail_from, mail_from_name: @delivery_mail.mail_from_name, mail_send_status_type: @delivery_mail.mail_send_status_type, mail_status_type: @delivery_mail.mail_status_type, owner_id: @delivery_mail.owner_id, planned_setting_at: @delivery_mail.planned_setting_at, send_end_at: @delivery_mail.send_end_at, subject: @delivery_mail.subject }, id: @delivery_mail.id, back_to: "back_to_address"
    end
    
    assert_redirected_to({controller: "bp_pic_groups/#{@delivery_mail.bp_pic_group_id}", back_to: "back_to_address", delivery_mail_id: assigns(:delivery_mail).id})
  end

  test "should show delivery_mail" do
    get :show, id: @delivery_mail
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @delivery_mail
    assert_response :success
  end

  test "should update delivery_mail" do
    put :update, id: @delivery_mail, delivery_mail: { bp_pic_group_id: @delivery_mail.bp_pic_group_id, content: @delivery_mail.content, id: @delivery_mail.id, mail_bcc: @delivery_mail.mail_bcc, mail_cc: @delivery_mail.mail_cc, mail_from: @delivery_mail.mail_from, mail_from_name: @delivery_mail.mail_from_name, mail_send_status_type: @delivery_mail.mail_send_status_type, mail_status_type: @delivery_mail.mail_status_type, owner_id: @delivery_mail.owner_id, planned_setting_at: @delivery_mail.planned_setting_at, send_end_at: @delivery_mail.send_end_at, subject: @delivery_mail.subject }, back_to: "back_to_address"

    assert_redirected_to({controller: "bp_pic_groups/#{@delivery_mail.bp_pic_group_id}", back_to: "back_to_address", delivery_mail_id: assigns(:delivery_mail).id})
    
  end

  test "should destroy delivery_mail" do
    delete :destroy, id: @delivery_mail
    assert(DeliveryMail.where(id: @delivery_mail, deleted: 0))

    assert_redirected_to delivery_mails_path
  end
end
