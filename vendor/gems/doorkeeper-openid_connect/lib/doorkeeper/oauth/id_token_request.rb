# frozen_string_literal: true

module Doorkeeper
  module OAuth
    class IdTokenRequest
      attr_accessor :pre_auth, :auth, :resource_owner

      def initialize(pre_auth, resource_owner)
        @pre_auth       = pre_auth
        @resource_owner = resource_owner
      end

      def authorize
        @auth = Authorization::Token.new(pre_auth, resource_owner)
        if @auth.respond_to?(:issue_token!)
          @auth.issue_token!
        else
          @auth.issue_token
        end
        response
      end

      def deny
        pre_auth.error = :access_denied
        pre_auth.error_response
      end

      private

      def response
        id_token = Doorkeeper::OpenidConnect::IdToken.new(auth.token, pre_auth.nonce)

        IdTokenResponse.new(pre_auth, auth, id_token)
      end
    end
  end
end
