require 'test_helper'

class BpPicGroupTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test "bp_pic_group_name is unique" do
    group = BpPicGroup.new(bp_pic_group_name: "test group")
    same_name_group = BpPicGroup.new(bp_pic_group_name: "test group")
    
    assert_nothing_raised(ActiveRecord::RecordInvalid) do
      group.save!
    end
    assert_raise(ActiveRecord::RecordInvalid) do
      same_name_group.save!
    end
  end
  
  test "create clone bp_pic_group" do
    clone = BpPicGroup.new(bp_pic_group_name: "test_group")
    
    
    assert_difference('BpPicGroupDetail.count') do
      clone.save!
      clone.create_clone_group(1)
    end
    
    assert(!BpPicGroupDetail.where(bp_pic_group_id: clone.id).blank?)
  end
  
end
