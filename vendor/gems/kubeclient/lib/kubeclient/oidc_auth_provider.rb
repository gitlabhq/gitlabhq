# frozen_string_literal: true

module Kubeclient
  # Uses OIDC id-tokens and refreshes them if they are stale.
  class OIDCAuthProvider
    class OpenIDConnectDependencyError < LoadError # rubocop:disable Lint/InheritException
    end

    class << self
      def token(provider_config)
        begin
          require 'openid_connect'
        rescue LoadError => e
          raise OpenIDConnectDependencyError,
                'Error requiring openid_connect gem. Kubeclient itself does not include the ' \
                'openid_connect gem. To support auth-provider oidc, you must include it in your ' \
                "calling application. Failed with: #{e.message}"
        end

        issuer_url = provider_config['idp-issuer-url']
        discovery = OpenIDConnect::Discovery::Provider::Config.discover! issuer_url

        if provider_config.key? 'id-token'
          return provider_config['id-token'] unless expired?(provider_config['id-token'], discovery)
        end

        client = OpenIDConnect::Client.new(
          identifier: provider_config['client-id'],
          secret: provider_config['client-secret'],
          authorization_endpoint: discovery.authorization_endpoint,
          token_endpoint: discovery.token_endpoint,
          userinfo_endpoint: discovery.userinfo_endpoint
        )
        client.refresh_token = provider_config['refresh-token']
        client.access_token!.id_token
      end

      def expired?(id_token, discovery)
        decoded_token = OpenIDConnect::ResponseObject::IdToken.decode(
          id_token,
          discovery.jwks
        )
        # If token expired or expiring within 60 seconds
        Time.now.to_i + 60 > decoded_token.exp.to_i
      rescue JSON::JWK::Set::KidNotFound
        # Token cannot be verified: the kid it was signed with is not available for discovery
        # Consider it expired and fetch a new one.
        true
      end
    end
  end
end
