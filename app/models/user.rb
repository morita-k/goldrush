# -*- encoding: utf-8 -*-
require 'digest/sha1'
require 'auto_type_name'
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :confirmable#, :validatable

  # Setup accessible (or protected) attributes for your model
#  attr_accessible :email, :password, :password_confirmation, :remember_me
#  attr_accessible :email, :password, :password_confirmation, :remember_me, :login, :access_level_type
  # attr_accessible :title, :body

  # see. https://github.com/plataformatec/devise/wiki/How-To:-Allow-users-to-sign-in-using-their-username-or-email-address
#  before_create :create_login
  before_save :create_login

  after_save :purge_cache

  def formated_mail_from
    "\"#{nickname}\" <#{email}>"
  end

  def purge_cache
    User.purge_cache
  end
  
  @@cache = nil

  def User.load_cache
    @@cache = User.find(:all)
  end

  def User.purge_cache
    @@cache = nil
  end

  def User.getUsers
    @@cache = User.load_cache unless @@cache
    @@cache
  end

  def zone
    'Tokyo'
  end

  def zoned(&block)
    org = Time.zone
    Time.zone = zone
    return block.call
  ensure
    Time.zone = org
  end

  def zone_now
    zoned do
      return Time.zone.now
    end
  end

  def zone_at(at)
    zoned do
      return Time.zone.at(at.to_i)
    end
  end

  def zone_parse(str)
    zoned do
      return Time.zone.parse(str)
    end
  end

  def create_login
    self.login = self.email
    self.access_level_type ||= 'normal'
    self.per_page ||= 50
  end

  # (devise) customize condition for finding user
  def self.find_first_by_auth_conditions(conditions, opts={})
    super(conditions, opts.merge(:deleted => 0))
  end

  # (devise) customize condition for login
  def self.find_for_database_authentication(conditions)
    self.where(:login => conditions[:email], :deleted => 0).first || self.where(:email => conditions[:email], :deleted => 0).first
  end

  include AutoTypeName
  
  has_many :monthly_workings, :conditions => "monthly_workings.deleted = 0", :order => "start_date"
  has_many :holiday_applications, :conditions => "holiday_applications.deleted = 0"
  has_many :other_applications, :conditions => "other_applications.deleted = 0"
  has_many :business_trip_applications, :conditions => "business_trip_applications.deleted = 0"
  has_one :employee, :conditions => "employees.deleted = 0"
  has_one :route_expense, :conditions => "route_expenses.deleted = 0"
  has_one :vacation, :conditions => "vacations.deleted = 0"
  belongs_to :owner, :class_name => "Owner", :conditions => "owners.deleted = 0"
  belongs_to :contact_mail_template, :class_name => "MailTemplate", :conditions => "mail_templates.deleted = 0"
  has_many :employee_families, :conditions => "employee_families.deleted = 0"
  has_many :approval_authorities, :conditions => "approval_authorities.deleted = 0"
  has_many :annual_vacations, :conditions => "annual_vacations.deleted = 0", :order => "year"
  has_many :project_members, :conditions => "project_members.deleted = 0"
  validates_presence_of :nickname

  # customize devise :validatable attribute
  module Validatable
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        validates_presence_of     :email, if: :email_required?
        validates_uniqueness_of   :email, allow_blank: true, scope: [:deleted, :deleted_at]
        validates_format_of       :email, with: email_regexp, allow_blank: true, if: :email_changed?
        validates_presence_of     :password, if: :password_required?
        validates_confirmation_of :password, if: :password_required?
        validates_length_of       :password, within: password_length, allow_blank: true
      end
    end
  protected
    def password_required?; !persisted? || !password.nil? || !password_confirmation.nil? end
    def email_required?; true end
    module ClassMethods; Devise::Models.config(self, :email_regexp, :password_length) end
  end
  include Validatable

  def super?
    ["super"].include?(self.access_level_type)
  end

  def manager?
    ["super", "owner"].include?(self.access_level_type)
  end

  def owner?
    ["owner"].include?(self.access_level_type)
  end

  def normal?
    ["normal"].include?(self.access_level_type)
  end

  def enable_photo?
    super? || owner.enable_photo?
  end

  def enable_jiet?
    super? || owner.enable_jiet?
  end

  def enable_daily_report?
    super? || owner.enable_daily_report?
  end

  def enable_contract?
    super? || owner.enable_contract?
  end

  def enable_outflow_mail?
    super? || owner.enable_outflow_mail?
  end

  def advanced_smtp_mode_on?
    owner.advanced_smtp_mode_on?
  end

  def smtp_settings_enable_starttls_auto?
    self.smtp_settings_enable_starttls_auto == 1
  end

  def smtp_settings_authenticated?
    self.smtp_settings_authenticated_flg == 1
  end

  def User.pic_select_items(owner_id)
    User.where("users.owner_id = ? and users.deleted = 0 and access_level_type <> 'super'", owner_id).collect{|x| [x.nickname, x.id]}
  end
 
  def User.map_for_googleimport(owner_id)
    res = {}
    where(:owner_id => owner_id, :deleted => 0).each do |u|
      res[u.nickname] = u.id
    end
    res
  end

  def User.get_prefs
    [
      '北海道',
      '青森県',
      '岩手県',
      '宮城県',
      '秋田県',
      '山形県',
      '福島県',
      '茨城県',
      '栃木県',
      '群馬県',
      '埼玉県',
      '千葉県',
      '東京都',
      '神奈川県',
      '新潟県',
      '富山県',
      '石川県',
      '福井県',
      '山梨県',
      '長野県',
      '岐阜県',
      '静岡県',
      '愛知県',
      '三重県',
      '滋賀県',
      '京都府',
      '大阪府',
      '兵庫県',
      '奈良県',
      '和歌山県',
      '鳥取県',
      '島根県',
      '岡山県',
      '広島県',
      '山口県',
      '徳島県',
      '香川県',
      '愛媛県',
      '高知県',
      '福岡県',
      '佐賀県',
      '長崎県',
      '熊本県',
      '大分県',
      '宮崎県',
      '鹿児島県',
      '沖縄県',
      '国外',
      'その他'
    ]
  end

  protected
=begin
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end
    
    def password_required?
      (crypted_password.blank? || !password.blank?)
    end
=end

  def self.get_nickname(login)
    user = User.where(:login => login).first
    user.blank? || user.nickname.blank? ? login : user.nickname
  end
end

