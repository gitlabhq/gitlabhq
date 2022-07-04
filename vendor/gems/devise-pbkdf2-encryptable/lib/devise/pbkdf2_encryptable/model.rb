# frozen_string_literal: true

require 'devise/strategies/database_authenticatable'

# Based on `devise-encryptable` Encryptable model
# https://github.com/heartcombo/devise-encryptable/blob/main/lib/devise/encryptable/model.rb
module Devise
  module Models
    module Pbkdf2Encryptable
      extend ActiveSupport::Concern

      def valid_password?(password)
        encryptor_class.compare(encrypted_password, password)
      end

      def password_strategy
        split_encrypted_password[:strategy]&.tr('-', '_')&.to_sym
      end

      def password_salt
        split_encrypted_password[:salt]
      end

      # Used by warden and other modules where there is a
      # need for a random token based on the user password.
      alias_method :authenticatable_salt, :password_salt

      def password_stretches
        split_encrypted_password[:stretches]
      end

      def password_checksum
        split_encrypted_password[:checksum]
      end

      protected

      # Used by Devise DatabaseAuthenticatable when setting a password
      def password_digest(password)
        remove_instance_variable('@split_encrypted_password') if defined?(@split_encrypted_password)

        encryptor_class.digest(password, encryptor_class::STRETCHES, Devise.friendly_token[0, 16])
      end

      def encryptor_class
        self.class.encryptor_class
      end

      private

      def split_encrypted_password
        return {} unless encrypted_password.present?
        return @split_encrypted_password if defined?(@split_encrypted_password)

        @split_encrypted_password = encryptor_class.split_digest(encrypted_password)
      end

      module ClassMethods
        Devise::Models.config(self, :encryptor)

        # Returns the class for the configured encryptor.
        def encryptor_class
          @encryptor_class ||= case encryptor
                               when :bcrypt
                                 raise "In order to use bcrypt as encryptor, simply remove :pbkdf2_encryptable from your devise model"
                               when nil
                                 raise "You need to specify an :encryptor in Devise configuration in order to use :pbkdf2_encryptable"
                               else
                                 Devise::Pbkdf2Encryptable::Encryptors.const_get(encryptor.to_s.classify)
                               end
        rescue NameError
          raise "Configured encryptor '#{encryptor.to_sym}' could not be found for pbkdf2_encryptable"
        end
      end
    end
  end
end
