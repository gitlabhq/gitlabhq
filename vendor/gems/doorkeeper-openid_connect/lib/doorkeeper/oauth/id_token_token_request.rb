# frozen_string_literal: true

module Doorkeeper
  module OAuth
    class IdTokenTokenRequest < IdTokenRequest
      private

      def response
        id_token_token = Doorkeeper::OpenidConnect::IdTokenToken.new(auth.token, pre_auth.nonce)

        IdTokenTokenResponse.new(pre_auth, auth, id_token_token)
      end
    end
  end
end
