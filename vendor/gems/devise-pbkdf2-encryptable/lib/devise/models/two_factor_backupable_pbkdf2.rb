module Devise
  module Models
    module TwoFactorBackupablePbkdf2
      extend ActiveSupport::Concern

      # 1) Invalidates all existing backup codes
      # 2) Generates otp_number_of_backup_codes backup codes
      # 3) Stores the hashed backup codes in the database
      # 4) Returns a plaintext array of the generated backup codes
      #
      def generate_otp_backup_codes_pbkdf2!
        codes           = []
        number_of_codes = self.class.otp_number_of_backup_codes
        code_length     = self.class.otp_backup_code_length

        number_of_codes.times do
          codes << SecureRandom.hex(code_length / 2) # Hexstring has length 2*n
        end

        hashed_codes = codes.map do |code|
          Devise::Pbkdf2Encryptable::Encryptors::Pbkdf2Sha512.digest(
            code,
            Devise::Pbkdf2Encryptable::Encryptors::Pbkdf2Sha512::STRETCHES,
            Devise.friendly_token[0, 16])
        end

        self.otp_backup_codes = hashed_codes

        codes
      end

      # Returns true and invalidates the given code if that code is a valid
      #   backup code.
      #
      def invalidate_otp_backup_code_pdkdf2!(code)
        codes = self.otp_backup_codes || []

        codes.each do |backup_code|
          next unless Devise::Pbkdf2Encryptable::Encryptors::Pbkdf2Sha512.compare(backup_code, code)

          codes.delete(backup_code)
          self.otp_backup_codes = codes
          return true
        end

        false
      end

      protected

      module ClassMethods
        Devise::Models.config(self, :otp_backup_code_length,
                                    :otp_number_of_backup_codes,
                                    :pepper)
      end
    end
  end
end
