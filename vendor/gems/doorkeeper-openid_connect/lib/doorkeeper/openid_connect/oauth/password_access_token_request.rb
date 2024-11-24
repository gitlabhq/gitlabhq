# frozen_string_literal: true

module Doorkeeper
  module OpenidConnect
    module OAuth
      module PasswordAccessTokenRequest
        attr_reader :nonce

        if Gem.loaded_specs['doorkeeper'].version >= Gem::Version.create('5.5.1')
          def initialize(server, client, credentials, resource_owner, parameters = {})
            super
            @nonce = parameters[:nonce]
          end
        else
          def initialize(server, client, resource_owner, parameters = {})
            super
            @nonce = parameters[:nonce]
          end
        end

        private

        def after_successful_response
          id_token = Doorkeeper::OpenidConnect::IdToken.new(access_token, nonce)
          @response.id_token = id_token
          super
        end
      end
    end
  end

  OAuth::PasswordAccessTokenRequest.prepend OpenidConnect::OAuth::PasswordAccessTokenRequest
end
