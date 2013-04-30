# -*- encoding: utf-8 -*-
require 'nkf'
class ImportMail < ActiveRecord::Base

  belongs_to :business_partner
  belongs_to :bp_pic

  def ImportMail.tryConv(map, header_key, &block)
    str = nil
    begin
      if block_given?
        return block.call
      else
	return map[header_key].to_s
      end
    rescue Encoding::UndefinedConversionError => e
      return NKF.nkf('-w', map.header[header_key].value)
    end
  end
  
  def ImportMail.import_mail(m, src)
    ActiveRecord::Base::transaction do
      import_mail = ImportMail.new
      
      import_mail.in_reply_to = m.in_reply_to if m.in_reply_to
      import_mail.received_at = m.date.blank? ? Time.now : m.date
      subject = tryConv(m, 'Subject') { m.subject }
      import_mail.mail_subject = subject.blank? ? 'unknown subject' : subject
      import_mail.mail_from = m.from != nil ? m.from[0].to_s : "unknown"
      unless SysConfig.email_prodmode?
        import_mail.mail_from = StringUtil.to_test_address(import_mail.mail_from)
      end
      import_mail.set_bp
      import_mail.mail_sender_name = tryConv(m,'From')
      import_mail.mail_to = tryConv(m,'To')
      import_mail.mail_cc = tryConv(m,'Cc')
      import_mail.mail_bcc = tryConv(m,'Bcc')
      import_mail.message_source = src
      import_mail.message_id = m.message_id
      
      # attempt_fileのため(import_mail_idが必要)に一旦登録
      import_mail.save!
      
      # 添付ファイルがなければ案件、あれば人材と割り切る
      import_mail.biz_offer_flg = 1
      import_mail.bp_member_flg = 0
      #---------- mail_body ここから ----------
      if m.multipart?
        # パートに分かれている(=返信元メールや添付ファイルが存在している)場合
        m.parts.each do |part|
          if part.content_type.include?('multipart/alternative')
            # multipart/alternativeの場合、メール本文の含まれるパートなので、さらにその中のパートを調べる。
            part.parts.each do |ppart|
              if ppart.content_type == 'text/plain'
                # text/plainの場合、メール本文（返信だと添付ファイルの可能性も・・・）。
                import_mail.mail_body = get_encode_body(m, ppart.body)
                break
              end # ppart.content_type == 'text/plain'
            end # part.parts.each do
            if import_mail.mail_body.blank?
              # メール本文にまだ何も代入されてない(=プレーンテキストがなかった)場合、
              # 最初のbodyの値をエンコードして代入する
              import_mail.mail_body = get_encode_body(m, part.parts[0].body)
            end # import_mail.mail_body.blank?
          elsif !part.filename.blank?
            # filenameがある = 添付ファイル
            upfile = part.body.decoded
            #part.base64_decode
            file_name = part.filename.to_s
            
            attachment_file = AttachmentFile.new
            attachment_file.create_by_import(upfile, import_mail.id, file_name)
            import_mail.biz_offer_flg = 0
            import_mail.bp_member_flg = 1
          elsif part.content_type.include?('text/plain')
            # 添付ファイルでなくtext/plainの場合、メール本文。
            # 上書きされる可能性あり？
            import_mail.mail_body = get_encode_body(m, part.body)
          else
            # multipart/alternativeでもファイルでもtext/plainでもない場合は何もしない（ありえない？）
          end
        end # m.parts.each do
      else
        # パートに分かれていなければ、bodyをそのままエンコードして代入する
        import_mail.mail_body = get_encode_body(m, m.body)
      end # m.multipart?
      #---------- mail_body ここまで ----------
      
      import_mail.created_user = 'import_mail'
      import_mail.updated_user = 'import_mail'
      import_mail.save!
    end # transaction
  end
  
  def ImportMail.import
    Pop3Client.pop_mail do |m, src|
      puts">>>>>>>>>>>>>>>>>>>>>>>>>>> POP3 MAIL"
      ImportMail.import_mail(m, src)
    end # Pop3Client.pop_mail do
  end # def
  
  
  def wanted?
    self.unwanted != 1
  end

  def set_bp
    mail_from = self.mail_from
    mail_bp_pic = BpPic.find(:first, :conditions => ["deleted = 0 and email1 = ? or email2 = ?", mail_from, mail_from])
    if mail_bp_pic.blank?
      mail_business_partner = BusinessPartner.find(:first, :conditions => ["deleted = 0 and email = ?", mail_from])
      if !mail_business_partner.blank?
        self.business_partner_id = mail_business_partner.id
      end
    else
      self.bp_pic_id = mail_bp_pic.id
      self.business_partner_id = mail_bp_pic.business_partner.id
    end
  end

  def get_bizp(id)
    return BusinessPartner.find(id)
  end

  def get_bpic(id)
    return BpPic.find(id)
  end

  def attachment?
    AttachmentFile.count(:conditions => ["deleted = 0 and parent_table_name = 'import_mails' and parent_id = ?", self]) > 0
#    !AttachmentFile.find(:first, :conditions => ["deleted = 0 and parent_table_name = 'import_mails' and parent_id = ?", self]).blank?
  end
  
  def change_type(type_name)
    if type_name == "biz_offer"
      self.biz_offer_flg = 1
      self.save!
    end
  end

private
  def ImportMail.get_encode_body(mail, body)
    if mail.content_transfer_encoding == 'ISO-2022-JP'
      return NKF.nkf('-w -J', body)
    elsif mail.content_transfer_encoding == 'UTF-8'
      return body
    else
      # そのほかは
      return NKF.nkf('-w', body.to_s)
    end
  end

CTYPE_TO_EXT = {
  'image/jpeg' => 'jpeg',
  'image/gif'  => 'gif',
  'image/png'  => 'png',
  'image/tiff' => 'tiff',
  'application/vnd.ms-excel' => 'xls',
  'application/msword' => 'doc'
}

def ext( mail )
  CTYPE_TO_EXT[mail.content_type] || 'txt'
end



end
