# -*- encoding: utf-8 -*-
class SysConfig < ActiveRecord::Base
  
  validates_presence_of :config_section
  validates_presence_of :config_key
  validates_length_of :config_section, :maximum=>40
  validates_length_of :config_key, :maximum=>40
  validates_length_of :value1, :maximum=>255, :allow_blank => true
  validates_length_of :value2, :maximum=>255, :allow_blank => true
  validates_length_of :value3, :maximum=>255, :allow_blank => true

  after_save :purge_cache
  
  def purge_cache
    SysConfig.purge_cache
  end
  
  @@cache = nil

  # カラム名を受け取ってそれがシステムカラムなのかを返す
  def SysConfig.system_columns
    ['created_at','updated_at','lock_version','created_user','updated_user','deleted_at','deleted']
  end
  def SysConfig.system_column?(column)
    system_columns.include?(column)
  end

  def SysConfig.get_config(section, key, owner_id = 0)
    find(:first, :conditions => ["deleted = 0 and config_section = ? and config_key = ? and owner_id = ?", section, key, owner_id])
  end

  def SysConfig.get_value(section, key, owner_id = 0)
    config = SysConfig.get_config(section, key, owner_id)
    if config
      return config.value1
    else
      return nil
    end
  end

  def SysConfig.init_seq(key, seq, owner_id)
    x = find(:first, :conditions => ["deleted = 0 and config_section = 'seq' and config_key = ? and owner_id = ?", key, owner_id], :lock => true)
    if x
      x.value1 = seq
    else
      x = SysConfig.new
      x.owner_id = owner_id
      x.config_section = 'seq'
      x.config_key = key
      x.value1 = seq
    end
    x.created_user = 'init_seq' if x.new_record?
    x.updated_user = 'init_seq'
    x.save!
    return x
  end

  def SysConfig.get_seq_0(key, owner_id, col)
    seq = SysConfig.get_seq(key, owner_id)
    sprintf("%.#{col}d", seq)
  end

  def SysConfig.get_seq(key, owner_id)
    x = where(:owner_id => owner_id).find(:first, :conditions => ["deleted = 0 and config_section = 'seq' and config_key = ?", key], :lock => true)
    if x
      x.value1 = x.value1.to_i + 1
    else
      x = SysConfig.new
      x.owner_id = owner_id
      x.config_section = 'seq'
      x.config_key = key
      x.value1 = 1
    end
    x.created_user = 'get_seq' if x.new_record?
    x.updated_user = 'get_seq'
    x.save!
    return x.value1.to_i
  end
  
  def SysConfig.load_cache
    @@cache = SysConfig.find(:all, :conditions => "deleted = 0")
  end

  def SysConfig.purge_cache
    @@cache = nil
  end

  def self.get_configuration(section, key, owner_id = 0)
    load_cache unless @@cache
    @@cache.each do |conf|
      return conf if conf.config_section == section and conf.config_key == key and conf.owner_id == owner_id
    end
    return nil
#    SysConfig.find(:first, :conditions => ["deleted = 0 and config_section = ? and config_key = ? and owner_id = ?", section, key, owner_id])
  end

  def self.get_per_page_count
    if c = get_configuration('per_page_count', 'default')
      c.value1.to_i
    else
      40
    end
  end

  def self.email_prodmode?
    get_configuration("business_partners", "prodmode")
  end

  def self.get_indent_pattern
    get_configuration("analysis_templates", "indent").value1.gsub(/[\s　]/, "").split(",").reject{|s| s == ""}
  end
  def self.star_color
    {
      0 => 'silver',
      1 => '#ffea00',  # yellow
      2 => 'orangered', # orange
      3 => '#000000',
      4 => 'dimgray'
    }
  end

  def self.get_jiet_analysis_target_address
    get_configuration("import_mail", "jiet").value1
  end

  def self.get_delivery_mails_return_path
    if config = get_configuration("delivery_mails", "return_path")
      config.value1
    else
      nil
    end
  end

  def self.get_outflow_criterion
    get_configuration("outflow_mail", "outflow_criterion").value1
  end

  def self.get_api_login
    get_configuration("api_login", "username_password")
  end

  def self.get_system_notifier_destination
    get_configuration("system_notifier", "destination").value1
  end

  def self.get_system_notifier_from
    get_configuration("system_notifier", "from").value1
  end

  def self.get_system_notifier_url_prefix
    get_configuration("system_notifier", "url_prefix").value1
  end

  def self.get_smtp_secret_key
    get_configuration("smtp", "secret_key").value1
  end

  def self.get_application_name
    get_configuration("system_setting", "application_name").value1
  end

  def self.get_contact_address
    get_configuration("system_setting", "contact_address").value1
  end
end
