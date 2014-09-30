# -*- encoding: utf-8 -*-
class ScoreJournal < ActiveRecord::Base
  def self.update_score!(user_id, gain, action, target_id)
    user = User.find(user_id)
    user.score = user.score.to_i + gain
    user.updated_user = user.login
    user.save!

    new({
      :owner_id => user.owner_id,
      :user_id => user_id,
      :action => action,
      :target_id => target_id,
      :score => gain,
      :created_user => user.login,
      :updated_user => user.login,
    }).save!
  end

end
