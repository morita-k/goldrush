# -*- encoding: utf-8 -*-
require 'nkf'
require 'csv'
class BusinessPartner < ActiveRecord::Base
  before_create :set_default
  include AutoTypeName
  has_many :businesses, :conditions => ["businesses.deleted = 0"]
  has_many :bp_pics, :conditions => ["bp_pics.deleted = 0"]
  has_many :biz_offers, :conditions => ["biz_offers.deleted = 0"]
  has_many :bp_members, :conditions => ["bp_members.deleted = 0"]

  validates_presence_of :business_partner_name, :business_partner_short_name, :business_partner_name_kana
  validates_uniqueness_of :business_partner_code, :case_sensitive => false, :allow_blank => true, :scope => [:owner_id, :deleted, :deleted_at]
  validates_uniqueness_of :business_partner_name, :case_sensitive => false, :scope => [:owner_id, :deleted, :deleted_at]

  CSV_HEADER = "e-mail(*),Name(*),CompanyName(*),メモ1,メモ2,メモ3,メモ4,メモ5,取引先Id,担当者Id,グループ"

  def set_default
    self.sales_code = "S" + SysConfig.get_seq_0('sales_code', self.owner_id, 7)
  end

  def address
    "#{address1}#{address2}"
  end
  
  def business_partner_code_name
    self.sales_code + " " + business_partner_name
  end

  def basic_contract_concluded
    resultConclude = ""
    resultConclude += "甲" if basic_contract_first_party_status_type == 'concluded'
    resultConclude += "乙" if basic_contract_second_party_status_type == 'concluded'
    resultConclude
  end

  def basic_contract_concluded_format
    basic_contract_concluded.blank? ? "" : "[#{basic_contract_concluded}]"
  end

  def BusinessPartner.create_template_csv
    csv_data = [CSV_HEADER]
    csv_data << ["sample01@example.com", "テスト 太郎", "株式会社テスト", "999-1234", "東京都サンプル区テスト町99-9-99", "03-9999-9999", "1990/1/1", "代表取締役", 1, 1, "テストグループ"].join(',')
    csv_data << ["sample02@example.com", "テスト 次郎", "サンプル株式会社", "", "", "", "", "", "", "", ""].join(',')
    NKF.nkf("-s", csv_data.join("\n"))
  end
  def BusinessPartner.export_to_csv(owner_id)
    csv_data = "#{CSV_HEADER}\n"
    BpPic.where(:owner_id => owner_id, :deleted => 0).each do |x|
      csv_data << CSV.generate(:col_sep => ',', :quote_char => '"') {|row| row << [x.email1, x.bp_pic_name, x.business_partner.business_partner_name, "", "", "", "", "", x.business_partner.id, x.id, ""]}
    end
    NKF.nkf("-s", csv_data)
  end
  def BusinessPartner.import_from_csv(filename, owner_id, prodmode=false)
    File.open(filename, "r"){|file| import_from_csv_data(file, owner_id, prodmode)}
  end

  def BusinessPartner.create_business_partner(companies, owner_id, email, pic_name, company_name)
    unless companies[company_name.upcase]
      unless bp = BusinessPartner.where(:owner_id => owner_id, :business_partner_name => company_name, :deleted => 0).first
        bp = BusinessPartner.new
        bp.owner_id = owner_id
        bp.business_partner_name = company_name
        bp.business_partner_short_name = company_name
        bp.business_partner_name_kana = company_name
        bp.sales_status_type = 'listup'
        bp.basic_contract_first_party_status_type ||= 'none'
        bp.basic_contract_second_party_status_type ||= 'none'
        bp.email = email if pic_name.include?('担当者')
        bp.created_user = 'import'
        bp.updated_user = 'import'
        bp.save!
      end
      companies[company_name.upcase] = [bp, {}]
    end
    companies[company_name.upcase]
  end

  def BusinessPartner.create_bp_pic(companies, email, pic_name, company_name, memo = nil)
    bp, pics = companies[company_name.upcase]
    pic = BpPic.new
    pic.owner_id = bp.owner_id
    pic.business_partner_id = bp.id
    pic.bp_pic_name = pic_name
    pic.bp_pic_short_name = pic_name
    pic.bp_pic_name_kana = pic_name
    pic.email1 = email
    pic.memo = memo
    pic.working_status_type = 'working'
    pic.created_user = 'import'
    pic.updated_user = 'import'
    begin
      pic.save!
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error e.message + e.backtrace.join("\n") + pic.inspect
      pic = nil
    end
    pic
  end

  def BusinessPartner.import_from_csv_data(readable_data, owner_id, prodmode=false)
    ActiveRecord::Base.transaction do
      companies = {}
      bp_id_cache = []
      bp_pic_id_cache = []
      CSV.parse(NKF.nkf("-w", readable_data).gsub(/\r\n/, "\n").gsub(/\r/, "\n"), :row_sep => "\n").each do |row|
        # Read email
        email,pic_name,com,memo1,memo2,memo3,memo4,memo5,bp_id,bp_pic_id,group_name = row.map{|c| (c || '').gsub(/[\r\n]/, '')}
        next if email.to_s.strip.blank?
        next if email == 'e-mail(*)'
        email = StringUtil.to_test_address(email) unless prodmode

        a,b = com.split("　")
        company_name = StringUtil.strip_with_full_size_space(a)

        if pic_name =~ /(.*)様/
          pic_name =  $1
        end
        pic_name = StringUtil.strip_with_full_size_space(pic_name.to_s)
        if bp_id.blank?
          # bp新規登録
          bp, names = create_business_partner(companies, owner_id, email, pic_name, company_name)
          bp_id = bp.id
          bp_id_cache << bp.id unless bp_id_cache.include? bp.id
        else
          if bp_id_cache.include? bp_id.to_i
            bp_id = bp_id.to_i
          else
            bp = self.where(id: bp_id.to_i, deleted: 0).first
            if bp.present?
              bp_id = bp.id
              bp_id_cache << bp.id
              companies[company_name.upcase] = [bp, {}] unless companies[company_name.upcase]
            end
          end
        end
        if bp_pic_id.blank?
          # bp_pic新規登録
          pic = create_bp_pic(companies, email, pic_name, company_name, row[3..7].reject{|x| x.blank?}.join("\n"))
          if pic.present?
            bp_pic_id = pic.id
            bp_pic_id_cache << pic.id unless bp_pic_id_cache.include? pic.id
          end
        else
          if bp_pic_id_cache.include? bp_pic_id.to_i
            bp_pic_id = bp_pic_id.to_i
          else
            pic = BpPic.where(id: bp_pic_id.to_i, deleted: 0).first
            if pic.present?
              bp_pic_id = pic.id
              bp_pic_id_cache << pic.id
            end
          end
=begin
        unless bp_pic_id_cache.include? bp_pic_id.to_i
          bp_pic_id_cache << bp_pic_id.to_i
          unless companies[company_name.upcase][pic.bp_pic_name.upcase]
            companies[company_name.upcase][pic.bp_pic_name.upcase] = pic
          end
        end
=end
        end

        # グループ登録
        unless group_name.blank?
          unless bp_pic_group = BpPicGroup.where(:owner_id => owner_id, :deleted => 0, :bp_pic_group_name => group_name).first
            bp_pic_group = BpPicGroup.new
            bp_pic_group.owner_id = owner_id
            bp_pic_group.bp_pic_group_name = group_name
            bp_pic_group.created_user = 'import'
            bp_pic_group.updated_user = 'import'
            bp_pic_group.save!
          end
          unless bp_pic_id.blank?
            unless bp_pic_group_detail = BpPicGroupDetail.where(:owner_id => owner_id, :bp_pic_group_id => bp_pic_group.id, :bp_pic_id => bp_pic_id).first
              bp_pic_group_detail = BpPicGroupDetail.new
              bp_pic_group_detail.owner_id = owner_id
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
  end

  # 名刺管理アカウントから出力されたCSVファイルをインポート(google.csv)
  def BusinessPartner.import_google_csv_data(readable_file, owner_id, userlogin, prodmode=false)
    BusinessPartnerGoogleImporter.import_google_csv_data(readable_file, owner_id, userlogin, prodmode)
  end
end
