# -*- encoding: utf-8 -*-
require 'nkf'
class BusinessPartner < ActiveRecord::Base
  before_create :set_default
  include AutoTypeName
  has_many :businesses, :conditions => ["businesses.deleted = 0"]
  has_many :bp_pics, :conditions => ["bp_pics.deleted = 0"]
  has_many :biz_offers, :conditions => ["biz_offers.deleted = 0"]
  has_many :bp_members, :conditions => ["bp_members.deleted = 0"]

  validates_presence_of :business_partner_name, :business_partner_short_name, :business_partner_name_kana
  validates_uniqueness_of :business_partner_code, :case_sensitive => false, :allow_blank => true, :scope => [:deleted, :deleted_at]
  validates_uniqueness_of :business_partner_name, :case_sensitive => false, :scope => [:deleted, :deleted_at]

  def set_default
    self.sales_code = "S" + SysConfig.get_seq_0('sales_code', 7)
  end

  def address
    "#{address1}#{address2}"
  end
  
  def business_partner_code_name
    self.sales_code + " " + business_partner_name
  end

  def BusinessPartner.export_to_csv
    csv_data = []
    csv_data << "e-mail,Name,ZipCode,Prefecture,Address,Tel,Birthday,Occupation,案件,人材, bp_id, bp_pic_id,グループ"
    BpPic.all.each do |x|
      csv_data << [x.email1, x.bp_pic_name,x.business_partner.business_partner_name, "", "", "", "", "", x.business_partner.down_flg, x.business_partner.upper_flg, x.business_partner.id, x.id].join(',')
    end
    return NKF.nkf("-s", csv_data.join("\n"))
  end
  def BusinessPartner.import_from_csv(filename, prodmode=false)
    File.open(filename, "r"){|file| import_from_csv_data(file, prodmode)}
  end

  def BusinessPartner.create_business_partner(companies, email, pic_name, company_name, upper_flg, down_flg)
    unless companies[company_name.upcase]
      unless bp = BusinessPartner.where(:business_partner_name => company_name, :deleted => 0).first
        bp = BusinessPartner.new
        bp.business_partner_name = company_name
        bp.business_partner_short_name = company_name
        bp.business_partner_name_kana = company_name
        bp.sales_status_type = 'prospect'
        bp.basic_contract_status_type ||= 'none'
        bp.nda_status_type ||= 'none'
        bp.upper_flg = upper_flg
        bp.down_flg = down_flg
        if pic_name.include?('担当者')
          bp.email = email
        end
        bp.created_user = 'import'
        bp.updated_user = 'import'
        bp.save!
      end
      companies[company_name.upcase] = [bp, {}]
    end
    return companies[company_name.upcase]
  end

  def BusinessPartner.create_bp_pic(companies, email, pic_name, company_name, memo = nil)
    bp, pics = companies[company_name.upcase]
    pic = BpPic.new
    pic.business_partner_id = bp.id
    pic.bp_pic_name = pic_name
    pic.bp_pic_short_name = pic_name
    pic.bp_pic_name_kana = pic_name
    pic.email1 = email
    pic.memo = memo
    pic.created_user = 'import'
    pic.updated_user = 'import'
    begin
      pic.save!
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error e.message + e.backtrace.join("\n") + pic.inspect
    end
    return pic
  end

  def BusinessPartner.import_from_csv_data(readable_data, prodmode=false)
    ActiveRecord::Base.transaction do
    require 'csv'
    companies = {}
    bp_id_cache = []
    bp_pic_id_cache = []
    CSV.parse(NKF.nkf("-w", readable_data)).each do |row|
      # Read email
      email,pic_name,com,pref,address,tel,birth,occupa,down_flg,upper_flg,bp_id,bp_pic_id,group = row
      next if email.to_s.strip.blank?
      next if email == 'e-mail'
      email = StringUtil.to_test_address(email) unless prodmode

      a,b = com.split("　")
      company_name = StringUtil.strip_with_full_size_space(a)

      if pic_name =~ /(.*)様/
        pic_name =  $1
      end
      pic_name = StringUtil.strip_with_full_size_space(pic_name.to_s)
      if bp_id.blank?
        # bp新規登録
        bp, names = create_business_partner(companies, email, pic_name, company_name, upper_flg, down_flg)
        bp_id = bp.id
        bp_id_cache << bp.id
      else
        bp_id = bp_id.to_i
=begin
        unless bp_id_cache.include? bp_id.to_i
          bp_id_cache << bp_id.to_i
          bp = Businesspartner.find(bp_id)
          unless companies[bp.business_partner_name.upcase]
            companies[bp.business_partner_name.upcase] = [bp, {}]
          end
        end
=end
      end
      if bp_pic_id.blank?
        # bp_pic新規登録
        pic = create_bp_pic(companies, email, pic_name, company_name, row[3..7].reject{|x| x.blank?}.join("\n"))
        bp_pic_id = pic.id
        bp_pic_id_cache << pic.id
      else
        bp_pic_id = bp_pic_id.to_i
=begin
        unless bp_pic_id_cache.include? bp_pic_id.to_i
          bp_pic_id_cache << bp_pic_id.to_i
          pic = BpPic.find(bp_pic_id)
          unless companies[company_name.upcase][pic.bp_pic_name.upcase]
            companies[company_name.upcase][pic.bp_pic_name.upcase] = pic
          end
        end
=end
      end
      # グループ登録
      unless group.blank?
        unless bp_pic_group = BpPicGroup.where(:deleted => 0, :bp_pic_group_name => group).first
          bp_pic_group = BpPicGroup.new
          bp_pic_group.bp_pic_group_name = group
          bp_pic_group.created_user = 'import'
          bp_pic_group.updated_user = 'import'
          bp_pic_group.save! 
        end
        unless bp_pic_group_detail = BpPicGroupDetail.where(:bp_pic_group_id => :bp_pic_group_id, :bp_pic_id => bp_pic_id).first
          bp_pic_group_detail = BpPicGroupDetail.new
          bp_pic_group_detail.bp_pic_group_id = bp_pic_group.id
          bp_pic_group_detail.bp_pic_id = bp_pic_id
          bp_pic_group_detail.created_user = 'import'
          bp_pic_group_detail.updated_user = 'import'
          bp_pic_group_detail.save! 
        end
      end
    end
  end
end

  # 名刺管理アカウントから出力されたCSVファイルをインポート(google.csv)
  def BusinessPartner.import_google_csv_data(readable_file, userlogin, prodmode=false)
    BusinessPartnerGoogleImporter.import_google_csv_data(readable_file, userlogin, prodmode)
  end
end
