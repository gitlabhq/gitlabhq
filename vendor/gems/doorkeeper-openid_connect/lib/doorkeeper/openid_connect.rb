# frozen_string_literal: true

require 'doorkeeper'
require 'active_model'
require 'jwt'

require 'doorkeeper/request'
require 'doorkeeper/request/id_token'
require 'doorkeeper/request/id_token_token'
require 'doorkeeper/oauth/id_token_request'
require 'doorkeeper/oauth/id_token_token_request'
require 'doorkeeper/oauth/id_token_response'
require 'doorkeeper/oauth/id_token_token_response'

require 'doorkeeper/openid_connect/claims_builder'
require 'doorkeeper/openid_connect/claims/claim'
require 'doorkeeper/openid_connect/claims/normal_claim'
require 'doorkeeper/openid_connect/config'
require 'doorkeeper/openid_connect/engine'
require 'doorkeeper/openid_connect/errors'
require 'doorkeeper/openid_connect/id_token'
require 'doorkeeper/openid_connect/id_token_token'
require 'doorkeeper/openid_connect/user_info'
require 'doorkeeper/openid_connect/version'

require 'doorkeeper/openid_connect/helpers/controller'

require 'doorkeeper/openid_connect/oauth/authorization/code'
require 'doorkeeper/openid_connect/oauth/authorization_code_request'
require 'doorkeeper/openid_connect/oauth/password_access_token_request'
require 'doorkeeper/openid_connect/oauth/pre_authorization'
require 'doorkeeper/openid_connect/oauth/token_response'

require 'doorkeeper/openid_connect/orm/active_record'

require 'doorkeeper/openid_connect/rails/routes'

module Doorkeeper
  module OpenidConnect
    def self.signing_algorithm
      configuration.signing_algorithm.to_s.upcase.to_sym
    end

    def self.signing_key
      key =
        if %i[HS256 HS384 HS512].include?(signing_algorithm)
          configuration.signing_key
        else
          OpenSSL::PKey.read(configuration.signing_key)
        end
      ::JWT::JWK.new(key, { kid_generator: ::JWT::JWK::Thumbprint })
    end

    def self.signing_key_normalized
      signing_key.export
    end

    Doorkeeper::GrantFlow.register(
      :id_token,
      response_type_matches: 'id_token',
      response_mode_matches: %w[fragment form_post],
      response_type_strategy: Doorkeeper::Request::IdToken,
    )

    Doorkeeper::GrantFlow.register(
      'id_token token',
      response_type_matches: 'id_token token',
      response_mode_matches: %w[fragment form_post],
      response_type_strategy: Doorkeeper::Request::IdTokenToken,
    )

    Doorkeeper::GrantFlow.register_alias(
      'implicit_oidc', as: ['implicit', 'id_token', 'id_token token']
    )
  end
end
