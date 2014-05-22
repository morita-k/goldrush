# -*- encoding: utf-8 -*-
require 'digest/sha1'
require 'auto_type_name'
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
#  attr_accessible :email, :password, :password_confirmation, :remember_me
#  attr_accessible :email, :password, :password_confirmation, :remember_me, :login, :access_level_type
  # attr_accessible :title, :body

  # see. https://github.com/plataformatec/devise/wiki/How-To:-Allow-users-to-sign-in-using-their-username-or-email-address
#  before_create :create_login
  before_save :create_login

  after_save :purge_cache

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
  end

  def self.find_for_database_authentication(conditions)
    self.where(:login => conditions[:email]).first || self.where(:email => conditions[:email]).first
  end

  include AutoTypeName
  
  has_many :monthly_workings, :conditions => "monthly_workings.deleted = 0", :order => "start_date"
  has_many :holiday_applications, :conditions => "holiday_applications.deleted = 0"
  has_many :other_applications, :conditions => "other_applications.deleted = 0"
  has_many :business_trip_applications, :conditions => "business_trip_applications.deleted = 0"
  has_one :employee, :conditions => "employees.deleted = 0"
  has_one :route_expense, :conditions => "route_expenses.deleted = 0"
  has_one :vacation, :conditions => "vacations.deleted = 0"
  belongs_to :contact_mail_template, :class_name => "MailTemplate", :conditions => "mail_templates.deleted = 0"
  has_many :employee_families, :conditions => "employee_families.deleted = 0"
  has_many :approval_authorities, :conditions => "approval_authorities.deleted = 0"
  has_many :annual_vacations, :conditions => "annual_vacations.deleted = 0", :order => "year"
  has_many :project_members, :conditions => "project_members.deleted = 0"
  
  def super?
    ["super"].include?(self.access_level_type)
  end

  def approver?
    employee.approver_flg == 1
  end

  def sales?
    employee.department_id == 1 # TODO: 固定でIDをみているのは危険
  end

  def User.pic_select_items
    User.find(:all, :conditions => "deleted = 0").collect{|x| [x.employee.employee_short_name, x.id]}
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

