# -*- encoding: utf-8 -*-
class AttachmentFile < ActiveRecord::Base
  include AutoTypeName

  belongs_to :parent, :class_name => 'BpMember'

  def AttachmentFile.get_attachment_files(parent_table_name, parent_id)
    where(:parent_table_name => parent_table_name, :parent_id => parent_id, :deleted => 0).order(:id)
  end

  def read_file
    @read_file ||= File.binread(file_path)
  end

  # 拡張子チェックと取得
  def check_and_get_ext(filename)
    ext = File.extname(filename.to_s).downcase

    if ext.blank?
      # 取れてない場合はUTF-8コードなのにisoだって言い張ってる困ったチャンだと思われる。
      # UTF-8にしちゃう。
      File.open("ext_test.txt", "wb"){ |f| f.write filename}
      ext = File.extname(NKF.nkf('-w', file_name)).downcase
    end

    if !['.txt', '.jpg', '.gif', '.png', '.doc', '.docx', '.xls', '.xlsx', '.pdf'].include?(ext)
#      raise ValidationAbort.new("拡張子がtxt, jpg, gif, png, doc, docx, xls, xlsx, pdfのファイルでなければなりません")
    end

    ext
  end

  # 保管フォルダ指定
  def file_dir
    @file_dir || 'files'
  end

  def file_dir=(file_dir)
    @file_dir = file_dir
  end

  def parend_table_dir
     File.join(file_dir, parent_table_name)
  end

  # idの下二けたをディレクトリ名とする
  def detail_dir
    File.join(parend_table_dir, sprintf("%.2d", self.id % 100))
  end

  # 経歴書の保存ファイル名生成
  def create_store_parent_table_name
    # 「親テーブル名_親テーブルId_添付ファイルId.拡張子」
    "#{self.parent_table_name}_#{self.parent_id}_#{self.id}#{self.extention}"
  end


  def create_by_import(upfile, parent_id, file_name)
    create_and_store!(upfile, parent_id, file_name, "import_mails", "import_mail")
  end

  def create_and_store!(upfile, parent_id, file_name, parent_table_name, loginuser)
    ActiveRecord::Base::transaction do
      # attachmentFileに項目を入れるメソッド
      # 親テーブル名
      self.parent_table_name = parent_table_name
      # 親テーブルId
      self.parent_id = parent_id
      # 添付ファイル名（オリジナルのファイル名）
      if file_name =~ /"(.*)"/
        file_name = $1
      end
      self.file_name = file_name
      # 拡張子
      ext = self.check_and_get_ext(file_name)
      self.extention = ext
      self.file_path = 'temp' # 後で変える。not nullなので一時的にtempとする

      self.created_user = loginuser
      self.updated_user = loginuser
      self.save! # idが欲しい

      self.file_path = File.join(detail_dir, create_store_parent_table_name)
      self.save!

      make_store_dir

      do_store(upfile, self.file_path)
    end
  end

  def self.set_property_file(owner_id, import_mail_id)
    target_files = AttachmentFile.where(:owner_id => owner_id, :parent_id => import_mail_id)

    target_attachment_ids = []
    p target_files
    target_files.each do |target_file|
      if /.doc|.docx|.xls|.xlsx/ =~ target_file.extention
        target_attachment_ids.push(target_file.id)
      end
    end

    unless target_attachment_ids.blank?
      call_poi_modify_property(target_attachment_ids, Owner.find(owner_id).company_name)
    end
  end

  def self.call_poi_modify_property(target_attachment_ids, author = nil)
    java_dir = File.join(Rails.root, 'java')
    sep = ENV["OS"] ? ";" : ":" # Windows or UNIX??
    class_path = ["#{java_dir}","#{java_dir}/lib/*"].join(sep)
    host = ActiveRecord::Base.configurations[ENV['RAILS_ENV']]['host']
    if host.nil? || host[0] == '/'[0] # hostの一文字目が'/'だったらUNIX SOCKETと判断
      host = 'localhost'
    end
    username = ActiveRecord::Base.configurations[ENV['RAILS_ENV']]['username']
    password = ActiveRecord::Base.configurations[ENV['RAILS_ENV']]['password']
    if password.blank?
      password = '\"\"'
    end
    database = ActiveRecord::Base.configurations[ENV['RAILS_ENV']]['database']

    unless author.blank?
      command = "java -classpath #{class_path} gd/SetPoiProperty jdbc:mysql://#{host}:3306/#{database} #{username} #{password} #{target_attachment_ids.join(',')} #{Rails.root} #{author}"
      logger.debug(command)
      result = `#{command}`
    end
  end

private
  def make_store_dir
    Dir.mkdir file_dir unless File.exist? file_dir
    Dir.mkdir parend_table_dir unless File.exist? parend_table_dir
    Dir.mkdir detail_dir unless File.exist? detail_dir
  end

  # 保管
  def do_store(upfile, store_file_name)
    if upfile.respond_to? 'read'
      store_file(upfile, store_file_name)
    else
      store_str(upfile, store_file_name)
    end
  end

  def store_file(upfile, store_file_name)
    store_internal(upfile, store_file_name){|x| x.read }
  end

  def store_str(upfile, store_file_name)
    store_internal(upfile, store_file_name){|x| x }
  end

  def store_internal(upfile, store_file_name, &block)
    File.open(store_file_name, "wb"){ |f| f.write(block.call(upfile)) }
  end

end
