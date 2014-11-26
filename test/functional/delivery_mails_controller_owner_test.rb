# -*- encoding: utf-8 -*-
require 'test_helper'

class DeliveryMailsControllerOwnerTest < ActionController::TestCase
  setup do
    @controller = DeliveryMailsController.new
    login_user = users(:users_16)
  	sign_in login_user
    @owner_id = login_user.owner_id
    @delivery_mail = delivery_mails(:delivery_mails_3)
    @delivery_mail_params = {
      bp_pic_group_id: 2,
      subject: "test mail",
      content: "test",
      planned_setting_at: DateTime.now.strftime("%Y/%m/%d"),
      planned_setting_at_hour: DateTime.now.hour,
      planned_setting_at_minute: DateTime.now.min
    }
    @attachment1 = fixture_file_upload('files/test_attachment_file_01.xls', 'application/vnd.ms-excel', :binary)
    request.env['REQUEST_URI'] = ""
  end

  test "should get index" do
  	current_owner_delivery_mails = DeliveryMail.where(:owner_id => @owner_id)

    get :index, :bp_pic_group_id => BpPicGroup.where(:owner_id => @owner_id).first.id
    delivery_mails = assigns(:delivery_mails).select {|delivery_mail| delivery_mail.owner_id == @owner_id}

    assert_equal(current_owner_delivery_mails.size, delivery_mails.size)
  end

  test "should create delivery_mail" do
    assert_difference("DeliveryMail.where(:owner_id => #{@owner_id}).count", +1) do
      assert_difference("AttachmentFile.where(:owner_id => #{@owner_id}).count", +1) do
        post :create, delivery_mail: @delivery_mail_params, attachment1: @attachment1, back_to: "/bp_pic_groups"
      end
    end

    created_delivery_mail = DeliveryMail.order("id desc").first
    assert_redirected_to "/bp_pic_groups/#{created_delivery_mail.bp_pic_group_id}?back_to=%2Fbp_pic_groups&delivery_mail_id=#{created_delivery_mail.id}"
  end

  test "should copy delivery_mail" do
    src_mail_id = 3
    af_count = AttachmentFile.get_attachment_files('delivery_mails', src_mail_id).count
    assert_difference("DeliveryMail.where(:owner_id => #{@owner_id}).count", +1) do
      assert_difference("AttachmentFile.where(:owner_id => #{@owner_id}).count", +(af_count+1)) do
        post :create, src_mail_id: af_count.to_s, delivery_mail: @delivery_mail_params, attachment1: @attachment1, back_to: "/bp_pic_groups"
      end
    end

    created_delivery_mail = DeliveryMail.order("id desc").first
    assert_redirected_to "/bp_pic_groups/#{created_delivery_mail.bp_pic_group_id}?back_to=%2Fbp_pic_groups&delivery_mail_id=#{created_delivery_mail.id}"
  end

  test "should create delivery_mail(contact_mail_create)" do
    bp_pic_ids = [5, 6]
    assert_difference("DeliveryMail.where(:owner_id => #{@owner_id}).count", +1) do
      assert_difference("AttachmentFile.where(:owner_id => #{@owner_id}).count", +1) do
        assert_difference("DeliveryMailTarget.where(:owner_id => #{@owner_id}).count", bp_pic_ids.size) do
          assert_no_difference("DeliveryError.count") do
            post :create, bp_pic_ids: bp_pic_ids.join(' '), delivery_mail: @delivery_mail_params, attachment1: @attachment1, back_to: "/bp_pic"
          end
        end
      end
    end

    assert_redirected_to "/bp_pic"
  end

  test "should create delivery_mail(reply_mail_create)" do
    source_bp_pic = BpPic.where(:owner_id => @owner_id).first

    assert_difference("DeliveryMail.where(:owner_id => #{@owner_id}).count", +1) do
      assert_difference("AttachmentFile.where(:owner_id => #{@owner_id}).count", +1) do
        assert_difference("DeliveryMailTarget.where(:owner_id => #{@owner_id}).count", +1) do
          assert_no_difference("DeliveryError.count") do
            post :create, source_bp_pic_id: source_bp_pic.id, delivery_mail: @delivery_mail_params, attachment1: @attachment1, back_to: "/import_mail/show/1"
          end
        end
      end
    end

    assert_redirected_to "/import_mail/show/1"
  end

  test "should get index by another owner" do
    sign_in users(:users_1)
    get :index, :bp_pic_group_id => BpPicGroup.where(:owner_id => users(:users_1).owner_id).first.id
    delivery_mails = assigns(:delivery_mails).select {|dm| dm.owner_id == @owner_id}
    assert_empty(delivery_mails)
    assert_response :success
  end

end

