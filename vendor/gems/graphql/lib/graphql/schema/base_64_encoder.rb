# frozen_string_literal: true
require "base64"
module GraphQL
  class Schema
    # @api private
    module Base64Encoder
      def self.encode(unencoded_text, nonce: false)
        Base64.urlsafe_encode64(unencoded_text, padding: false)
      end

      def self.decode(encoded_text, nonce: false)
        # urlsafe_decode64 is for forward compatibility
        Base64.urlsafe_decode64(encoded_text)
      rescue ArgumentError
        raise GraphQL::ExecutionError, "Invalid input: #{encoded_text.inspect}"
      end
    end
  end
end
