# frozen_string_literal: true

require 'digest/sha2'

module GraphQL
  class Query
    # @api private
    # @see Query#query_fingerprint
    # @see Query#variables_fingerprint
    # @see Query#fingerprint
    module Fingerprint
      # Make an obfuscated hash of the given string (either a query string or variables JSON)
      # @param string [String]
      # @return [String] A normalized, opaque hash
      def self.generate(input_str)
        # Implemented to be:
        # - Short (and uniform) length
        # - Stable
        # - Irreversibly Opaque (don't want to leak variable values)
        # - URL-friendly
        bytes = Digest::SHA256.digest(input_str)
        Base64.urlsafe_encode64(bytes)
      end
    end
  end
end
