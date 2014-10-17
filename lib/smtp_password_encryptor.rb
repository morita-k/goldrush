# -*- encoding: utf-8 -*-
module SmtpPasswordEncryptor
  def self.encrypt(password)
    self._new_encryptor.encrypt_and_sign(password)
  end

  def self.decrypt(encrypted_password)
    self._new_encryptor.decrypt_and_verify(encrypted_password)
  end

private
  def self._new_encryptor
    ActiveSupport::MessageEncryptor.new(SysConfig.get_smtp_secret_key, cipher: 'aes-256-cbc')
  end
end
