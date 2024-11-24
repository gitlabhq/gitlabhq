# frozen_string_literal: true

module Doorkeeper
  module OpenidConnect
    module AccessGrant
      def self.prepended(base)
        base.class_eval do
          has_one :openid_request,
            class_name: 'Doorkeeper::OpenidConnect::Request',
            foreign_key: 'access_grant_id',
            inverse_of: :access_grant,
            dependent: :delete
        end
      end
    end
  end
end
