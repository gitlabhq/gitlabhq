# frozen_string_literal: true

module Doorkeeper
  module OpenidConnect
    module OAuth
      module TokenResponse
        attr_accessor :id_token

        def body
          if token.includes_scope? 'openid'
            id_token = self.id_token || Doorkeeper::OpenidConnect::IdToken.new(token)

            super
              .merge(id_token: id_token.as_jws_token)
              .reject { |_, value| value.blank? }
          else
            super
          end
        end
      end
    end
  end

  OAuth::TokenResponse.prepend OpenidConnect::OAuth::TokenResponse
end
