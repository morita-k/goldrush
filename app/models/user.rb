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
      return Time.zone.at(at)
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
  has_many :comments, :conditions => "comments.deleted = 0"
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
  
=begin
  attr_protected :activated_at
  # Virtual attribute for the unencrypted password
  attr_accessor :password
  attr_accessor :activate_url
  attr_accessor :forgot_password_url
  attr_accessor :site_url

  #validates_presence_of     :login, :email
  validates_presence_of     :login
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :login,    :within => 3..40
  #validates_length_of       :email,    :within => 3..100
  #validates_uniqueness_of   :login, :email, :case_sensitive => false
  validates_uniqueness_of   :login, :case_sensitive => false
  #validates_format_of :email, :with => /(^([^@\s]+)@((?:[-_a-z0-9]+\.)+[a-z]{2,})$)|(^$)/i
  before_save :encrypt_password
  
  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    if ENV['ENABLE_MAIL_ACTIVATE']
      # hide records with a nil activated_at
      u = find :first, :conditions => ['login = ? and activated_at IS NOT NULL', login]
    else
      u = find_by_login(login) # need to get the salt
    end
    e = find :first, :include => [:employee], :conditions => ['(users.id = employees.user_id) and (users.login = ?) and ((employees.resignation_date IS NULL) OR (employees.resignation_date >= ?))', login, Date.today]
    e && u && u.authenticated?(password) ? u : nil
  end

#  before_create :make_activation_code if ENV['ENABLE_MAIL_ACTIVATE']

  # Activates the user in the database.
  def activate
    ActiveRecord::Base.transaction do
      @activated = true
      self.activated_at = Time.now
      self.activation_code = nil
      self.updated_user = 'activate'
      save!
    end
  end

  def forgot_password!
    @forgot_passworded = true
    self.activated_at = nil
    self.updated_user = 'forgot_password'
    self.save!
  end

  def forgot_password_fix
    self.activated_at = Time.now
    self.activation_code = nil
    self.updated_user = 'forgot_password_fix'
    self.save!
  end

  def recently_forgot_password?
    @forgot_passworded
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end

  # If you're going to use activation, uncomment this too
  def make_activation_code
    self.activate_send_at = Time.now
    self.activation_code = Digest::SHA1.hexdigest((self.nickname.to_s + self.login.to_s + (Time.now.to_s)).split(//).sort_by{rand}.join)
  end
#  protected :make_activation_code
  
  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end
=end
  def normal?
    ["normal","super"].include?(self.access_level_type)
  end

  def leader?
    ["leader","personnel_department","accounting","super"].include?(self.access_level_type)
  end

  def personnel_department?
    ["personnel_department","super"].include?(self.access_level_type)
  end

  def accounting?
    ["accounting","super"].include?(self.access_level_type)
  end

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
end

