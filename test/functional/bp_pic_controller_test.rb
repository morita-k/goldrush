# -*- encoding: utf-8 -*-
require 'test_helper'

class BpPicControllerTest < ActionController::TestCase
  setup do
  	sign_in users(:users_1)
  	@bp_pic = bp_pics(:bp_pics_1)
    request.env['REQUEST_URI'] = ""
  end

  test "delete group_detail in all mail groups then destroy bp_pic" do
   	before_details_count = BpPicGroupDetail.where(bp_pic_id: @bp_pic.id, deleted: 0).count
    assert_difference('BpPicGroupDetail.where(deleted: 0).count', -before_details_count) do
      delete :destroy, id: @bp_pic.id
    end
  end

end
