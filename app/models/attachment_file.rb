# -*- encoding: utf-8 -*-
class AttachmentFile < ActiveRecord::Base
  include AutoTypeName

  belongs_to :parent, :class_name => 'BpMember'
  
  def AttachmentFile.attachment_files(parent_table_name, parent_id)
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
    create_and_store!(upfile, parent_id, file_name, "import_mails")
  end

  def create_and_store!(upfile, parent_id, file_name, parent_table_name)
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
      
      self.created_user = 'import_mail'
      self.updated_user = 'import_mail'
      self.save! # idが欲しい
      
      self.file_path = File.join(detail_dir, create_store_parent_table_name)
      self.save!
      
      make_store_dir
      
      do_store(upfile, self.file_path)
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
