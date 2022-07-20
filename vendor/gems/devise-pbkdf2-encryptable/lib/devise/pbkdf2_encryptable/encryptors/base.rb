module Devise
  module Pbkdf2Encryptable
    module Encryptors
      class Base
        def self.split_digest(hash)
          split_digest = hash.split('$')
          _, strategy, stretches, salt, checksum = split_digest

          unless split_digest.length == 5 && strategy.start_with?('pbkdf2-')
            raise InvalidHash.new('invalid PBKDF2 hash')
          end

          { strategy: strategy, stretches: stretches.to_i,
            salt: passlib_decode64(salt), checksum: passlib_decode64(checksum) }
        end

        # Passlib-style Base64 encoding:
        # - Replaces '+' with '.'
        # - Strips trailing newline and '=='
        private_class_method def self.passlib_encode64(value)
          Base64.strict_encode64([value].pack('H*')).tr('+', '.').delete('=')
        end

        private_class_method def self.passlib_decode64(value)
          enc = value.tr('.', '+')
          Base64.decode64(enc).unpack1('H*')
        end

        # Passlib-style hash: $pbkdf2-sha512$rounds$salt$checksum
        # where salt and checksum are "adapted" Base64 encoded
        private_class_method def self.format_hash(strategy, stretches, salt, checksum)
          encoded_salt = passlib_encode64(salt)
          encoded_checksum = passlib_encode64(checksum)

          "$#{strategy}$#{stretches}$#{encoded_salt}$#{encoded_checksum}"
        end

        private_class_method def self.pbkdf2_checksum(hash, password, stretches, salt)
          raise 'Stretches must be greater than zero' unless stretches.to_i > 0

          OpenSSL::KDF.pbkdf2_hmac(
            password.to_s,
            salt: [salt].pack("H*"),
            iterations: stretches,
            hash: hash,
            length: hash.digest_length
          ).unpack1('H*')
        end
      end
    end
  end
end
