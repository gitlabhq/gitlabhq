# frozen_string_literal: true

module Doorkeeper
  module OpenidConnect
    def self.configure(&block)
      if Doorkeeper.configuration.orm != :active_record
        raise Errors::InvalidConfiguration, 'Doorkeeper OpenID Connect currently only supports the ActiveRecord ORM adapter'
      end

      @config = Config::Builder.new(&block).build
    end

    def self.configuration
      @config || (raise Errors::MissingConfiguration)
    end

    class Config
      class Builder
        def initialize(&block)
          @config = Config.new
          instance_eval(&block)
        end

        def build
          @config
        end

        def jws_public_key(*_args)
          puts 'DEPRECATION WARNING: `jws_public_key` is not needed anymore and will be removed in a future version, please remove it from config/initializers/doorkeeper_openid_connect.rb'
        end

        def jws_private_key(*args)
          puts 'DEPRECATION WARNING: `jws_private_key` has been replaced by `signing_key` and will be removed in a future version, please remove it from config/initializers/doorkeeper_openid_connect.rb'
          signing_key(*args)
        end
      end

      mattr_reader(:builder_class) { Config::Builder }

      extend ::Doorkeeper::Config::Option

      option :issuer
      option :signing_key
      option :signing_algorithm, default: :rs256
      option :subject_types_supported, default: [:public]

      option :resource_owner_from_access_token, default: lambda { |*_|
        raise Errors::InvalidConfiguration, I18n.translate('doorkeeper.openid_connect.errors.messages.resource_owner_from_access_token_not_configured')
      }

      option :auth_time_from_resource_owner, default: lambda { |*_|
        raise Errors::InvalidConfiguration, I18n.translate('doorkeeper.openid_connect.errors.messages.auth_time_from_resource_owner_not_configured')
      }

      option :reauthenticate_resource_owner, default: lambda { |*_|
        raise Errors::InvalidConfiguration, I18n.translate('doorkeeper.openid_connect.errors.messages.reauthenticate_resource_owner_not_configured')
      }

      option :select_account_for_resource_owner, default: lambda { |*_|
        raise Errors::InvalidConfiguration, I18n.translate('doorkeeper.openid_connect.errors.messages.select_account_for_resource_owner_not_configured')
      }

      option :subject, default: lambda { |*_|
        raise Errors::InvalidConfiguration, I18n.translate('doorkeeper.openid_connect.errors.messages.subject_not_configured')
      }

      option :expiration, default: 120

      option :claims, builder_class: ClaimsBuilder

      option :protocol, default: lambda { |*_|
        ::Rails.env.production? ? :https : :http
      }

      option :end_session_endpoint, default: lambda { |*_|
        nil
      }

      option :discovery_url_options, default: lambda { |*_|
        {}
      }
    end
  end
end
