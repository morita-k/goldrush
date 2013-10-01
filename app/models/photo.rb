# -*- encoding: utf-8 -*-
class Photo < ActiveRecord::Base
  include AutoTypeName

  def Photo.import_photo(src, sender)

    photo = Photo.new
    photo.photo_sender = sender
    photo.photo_status_type = :unfixed

    photo.create_and_store!(src, 'temp', src.original_filename, 'bp_pic', 'import_photo')
  end

  def Photo.update_bp_pic(bp_pic_id, photo_id)
    photo = find(photo_id)
    photo.photo_status_type = :fixed
    photo.parent_id = bp_pic_id

    photo.update_and_store!
  end

  def Photo.update_bp_pic_unlink(photo_id)
    photo = find(photo_id)
    photo.photo_status_type = :unfixed
    photo.parent_id = 0

    photo.save!

    photo.update_and_store!
  end

  def Photo.delete_photo(photo_id)
    photo = find(photo_id)

    photo.delete_and_store!

    photo.deleted = 9
    photo.deleted_at = Time.now
    photo.save!
  end

  def update_and_store!
    original_file = self.file_path
    original_thumbnail_file = self.thumbnail_path

    self.file_path = File.join(detail_dir, create_store_parent_table_name)
    self.thumbnail_path = File.join(detail_dir, create_store_parent_table_thumbnail_name)
    self.save!

    do_copy(original_file, self.file_path)
    do_copy(original_thumbnail_file, self.thumbnail_path)

  end

  def delete_and_store!
    original_file = self.file_path
    original_thumbnail_file = self.thumbnail_path

    do_delete(original_file)
    do_delete(original_thumbnail_file)

    folder_path = File::dirname(original_file)

    if Dir::entries(folder_path).size == 2
      Dir::rmdir(folder_path)
    end
  end

  def do_copy(original_file_path, copy_file_path)
    original_image = Magick::ImageList.new(original_file_path).first
    original_image.write(copy_file_path)

    File.delete(original_file_path)
  end

  def do_delete(original_file_path)
    if File.exist?(original_file_path)
      File.delete(original_file_path)
    end
  end

  def create_and_store!(upfile, parent_id, file_name, parent_table_name, loginuser)
    ActiveRecord::Base::transaction do
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
      self.thumbnail_path = 'temp'

      self.created_user = loginuser
      self.updated_user = loginuser
      self.save! # idが欲しい

      self.file_path = File.join(detail_dir, create_store_parent_table_name)
      self.thumbnail_path = File.join(detail_dir, create_store_parent_table_thumbnail_name)
      self.save!

      make_store_dir

      do_store(upfile, self.file_path)
      set_orientation_and_resize
      do_store_thumbnail

    end
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
    @file_dir || 'files/photos'
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

  def create_store_parent_table_name
    # 「親テーブル名_親テーブルId_添付ファイルId.拡張子」
    "#{self.parent_table_name}_#{self.parent_id}_#{self.id}#{self.extention}"
  end

  def create_store_parent_table_thumbnail_name
    # 「親テーブル名_親テーブルId_添付ファイルId.拡張子」
    "#{self.parent_table_name}_#{self.parent_id}_#{self.id}_tn#{self.extention}"
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

  def do_store_thumbnail
    image = Magick::ImageList.new(self.file_path).first
    image.scale!(0.3)
    image.write(self.thumbnail_path)
  end

  def set_orientation_and_resize
    original_image = Magick::ImageList.new(self.file_path).first
    original_image.resize_to_fit!(1028, 768)

    if "#{original_image.orientation}" == 'RightTopOrientation'
      original_image.rotate!(90)
    end

    original_image.write(self.file_path)
  end
end