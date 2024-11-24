# frozen_string_literal: true

module Doorkeeper
  module OAuth
    class IdTokenResponse < BaseResponse
      include OAuth::Helpers

      attr_accessor :pre_auth, :auth, :id_token

      def initialize(pre_auth, auth, id_token)
        @pre_auth = pre_auth
        @auth = auth
        @id_token = id_token
      end

      def redirectable?
        true
      end

      def body
        {
          expires_in: auth.token.expires_in_seconds,
          state: pre_auth.state,
          id_token: id_token.as_jws_token
        }
      end

      def redirect_uri
        Authorization::URIBuilder.uri_with_fragment(pre_auth.redirect_uri, body)
      end
    end
  end
end
