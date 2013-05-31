# -*- encoding: utf-8 -*-
class TagDetail < ActiveRecord::Base
  belongs_to :tag
  def TagDetail.create_tags!(tag_id, parent_id, tag_text, key)
    td = TagDetail.new
    td.tag_id = tag_id
    td.parent_id = parent_id
    td.tag_key = key
    td.tag_text = tag_text
    td.opened = 1
#    td.created_user = self.updated_user
#    td.updated_user = self.updated_user
    td.save!
  end
end

