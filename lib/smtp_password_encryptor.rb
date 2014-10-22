# -*- encoding: utf-8 -*-
module SmtpPasswordEncryptor
  # 暗号化
  # パスワードが空でも暗号化したパスワードを返す
  def self.encrypt(password)
    self._new_encryptor.encrypt_and_sign(password)
  end

  # 復号化
  # 復号化に失敗した場合、空文字を返す
  def self.decrypt(encrypted_password)
    begin
      self._new_encryptor.decrypt_and_verify(encrypted_password)
    rescue
      ''
    end
  end

private
  def self._new_encryptor
    ActiveSupport::MessageEncryptor.new(SysConfig.get_smtp_secret_key, cipher: 'aes-256-cbc')
  end
end
