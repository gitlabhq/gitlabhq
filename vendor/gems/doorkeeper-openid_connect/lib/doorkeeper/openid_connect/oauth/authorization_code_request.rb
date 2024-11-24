# frozen_string_literal: true

module Doorkeeper
  module OpenidConnect
    module OAuth
      module AuthorizationCodeRequest
        private

        def after_successful_response
          super

          nonce =
            if (openid_request = grant.openid_request)
              openid_request.destroy!
              openid_request.nonce
            end

          id_token = Doorkeeper::OpenidConnect::IdToken.new(access_token, nonce)
          @response.id_token = id_token
        end
      end
    end
  end

  OAuth::AuthorizationCodeRequest.prepend OpenidConnect::OAuth::AuthorizationCodeRequest
end
