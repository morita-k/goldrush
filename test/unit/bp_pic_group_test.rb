require 'test_helper'

class BpPicGroupTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test "bp_pic_group_name is unique" do
    group = BpPicGroup.new(bp_pic_group_name: "test group", matching_way_type: "other")
    same_name_group = BpPicGroup.new(bp_pic_group_name: "test group", matching_way_type: "other")

    assert_nothing_raised(ActiveRecord::RecordInvalid) do
      group.save!
    end
    assert_raise(ActiveRecord::RecordInvalid) do
      same_name_group.save!
    end
  end

  test "create clone bp_pic_group" do
    clone = BpPicGroup.new(owner_id: 1, bp_pic_group_name: "test_group", matching_way_type: "other")
    source = BpPicGroup.where(id: 1, deleted: 0)

    assert_difference('BpPicGroupDetail.count') do
      clone.save!
      clone.create_clone_group(1)
    end

    source_first_detail = source.shift.bp_pic_group_details.shift
    clone_first_detail = clone.bp_pic_group_details.shift

    assert(!BpPicGroupDetail.where(bp_pic_group_id: clone.id).blank?)
    # ↓Associationで生成してるし異なるのはそもそも自明？
    # assert_not_equal(source_first_detail.bp_pic_group_id, clone_first_detail.bp_pic_group_id)
    assert_equal(source_first_detail.bp_pic_id, clone_first_detail.bp_pic_id)
    assert_equal(source_first_detail.suspended, clone_first_detail.suspended)
  end

end
