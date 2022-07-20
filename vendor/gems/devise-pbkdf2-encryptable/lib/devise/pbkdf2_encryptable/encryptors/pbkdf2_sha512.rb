# frozen_string_literal: true

module Devise
  module Pbkdf2Encryptable
    module Encryptors
      class Pbkdf2Sha512 < Base
        STRATEGY = 'pbkdf2-sha512'
        STRETCHES = 20_000

        def self.compare(encrypted_password, password)
          split_digest = self.split_digest(encrypted_password)
          value_to_test = self.sha512_checksum(password, split_digest[:stretches], split_digest[:salt])

          Devise.secure_compare(split_digest[:checksum], value_to_test)
        end

        def self.digest(password, stretches, salt)
          checksum = sha512_checksum(password, stretches, salt)

          format_hash(STRATEGY, stretches, salt, checksum)
        end

        def self.split_digest(hash)
          split_digest = super

          unless split_digest[:strategy] == STRATEGY
            raise InvalidHash.new('invalid PBKDF2 SHA512 hash')
          end

          split_digest
        end

        private_class_method def self.sha512_checksum(password, stretches, salt)
          hash = OpenSSL::Digest.new('SHA512')

          pbkdf2_checksum(hash, password, stretches, salt)
        end
      end
    end
  end
end
