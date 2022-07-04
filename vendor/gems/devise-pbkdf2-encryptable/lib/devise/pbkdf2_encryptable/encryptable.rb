module Devise
  # Used to define the password encryption algorithm.
  mattr_accessor :encryptor
  @@encryptor = nil

  module Pbkdf2Encryptable
    module Encryptors
      InvalidHash = Class.new(StandardError)

      autoload :Base, 'devise/pbkdf2_encryptable/encryptors/base'
      autoload :Pbkdf2Sha512, 'devise/pbkdf2_encryptable/encryptors/pbkdf2_sha512'
    end
  end
end

Devise.add_module(:pbkdf2_encryptable, :model => 'devise/pbkdf2_encryptable/model')
