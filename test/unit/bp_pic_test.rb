# -*- encoding: utf-8 -*-
require 'test_helper'

class BpPicTest < ActiveSupport::TestCase
  
  test "delete group_detail in all mail groups then destroy bp_pic" do
    assert_difference('BpPicGroupDetail.where(deleted: 0).length', -1) do
      pic = BpPic.find(1)
      pic.out_of_group!
    end
  end

end