# -*- encoding: utf-8 -*-
class Invite < ActiveRecord::Base
  require 'digest/sha1'

  belongs_to :owner, :conditions => "owners.deleted = 0"
  validates_presence_of :email, :activation_code

  def calculate_activation_code
    return Digest::SHA1.hexdigest("#{owner_id}_#{email}_#{DateTime.now.to_s}")
  end

  def Invite.delete_old_invitation!(email, updated_user)
    deleted_at = Time.now
    where(:email => email, :deleted => 0).each do |invite|
      invite.deleted = 9
      invite.deleted_at = deleted_at
      invite.updated_user = updated_user
      invite.save!
    end
  end

  def Invite.send_invitation_mail(mail_sender, email, activation_code)
    InvitationMailer.send_mail(mail_sender, email, activation_code)
  end
end
