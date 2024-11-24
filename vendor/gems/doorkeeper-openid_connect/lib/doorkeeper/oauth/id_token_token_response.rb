# frozen_string_literal: true

module Doorkeeper
  module OAuth
    class IdTokenTokenResponse < IdTokenResponse
      def body
        super.merge({
          access_token: auth.token.token,
          token_type: auth.token.token_type
        })
      end
    end
  end
end
