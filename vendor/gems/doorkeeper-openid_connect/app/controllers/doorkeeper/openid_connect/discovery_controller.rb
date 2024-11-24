# frozen_string_literal: true

module Doorkeeper
  module OpenidConnect
    class DiscoveryController < ::Doorkeeper::ApplicationMetalController
      include Doorkeeper::Helpers::Controller

      WEBFINGER_RELATION = 'http://openid.net/specs/connect/1.0/issuer'

      def provider
        render json: provider_response
      end

      def webfinger
        render json: webfinger_response
      end

      def keys
        render json: keys_response
      end

      private

      def provider_response
        doorkeeper = ::Doorkeeper.configuration
        openid_connect = ::Doorkeeper::OpenidConnect.configuration

        {
          issuer: issuer,
          authorization_endpoint: oauth_authorization_url(authorization_url_options),
          token_endpoint: oauth_token_url(token_url_options),
          revocation_endpoint: oauth_revoke_url(revocation_url_options),
          introspection_endpoint: respond_to?(:oauth_introspect_url) ? oauth_introspect_url(introspection_url_options) : nil,
          userinfo_endpoint: oauth_userinfo_url(userinfo_url_options),
          jwks_uri: oauth_discovery_keys_url(jwks_url_options),
          end_session_endpoint: instance_exec(&openid_connect.end_session_endpoint),

          scopes_supported: doorkeeper.scopes,

          # TODO: support id_token response type
          response_types_supported: doorkeeper.authorization_response_types,
          response_modes_supported: response_modes_supported(doorkeeper),
          grant_types_supported: grant_types_supported(doorkeeper),

          # TODO: look into doorkeeper-jwt_assertion for these
          #  'client_secret_jwt',
          #  'private_key_jwt'
          token_endpoint_auth_methods_supported: %w[client_secret_basic client_secret_post],

          subject_types_supported: openid_connect.subject_types_supported,

          id_token_signing_alg_values_supported: [
            ::Doorkeeper::OpenidConnect.signing_algorithm
          ],

          claim_types_supported: [
            'normal',

            # TODO: support these
            # 'aggregated',
            # 'distributed',
          ],

          claims_supported: %w[
            iss
            sub
            aud
            exp
            iat
          ] | openid_connect.claims.to_h.keys,

          code_challenge_methods_supported: code_challenge_methods_supported(doorkeeper),
        }.compact
      end

      def grant_types_supported(doorkeeper)
        grant_types_supported = doorkeeper.grant_flows.dup
        grant_types_supported << 'refresh_token' if doorkeeper.refresh_token_enabled?
        grant_types_supported
      end

      def response_modes_supported(doorkeeper)
        doorkeeper.authorization_response_flows.flat_map(&:response_mode_matches).uniq
      end

      def code_challenge_methods_supported(doorkeeper)
        return unless doorkeeper.access_grant_model.pkce_supported?

        %w[plain S256]
      end

      def webfinger_response
        {
          subject: params.require(:resource),
          links: [
            {
              rel: WEBFINGER_RELATION,
              href: root_url(webfinger_url_options),
            }
          ]
        }
      end

      def keys_response
        signing_key = Doorkeeper::OpenidConnect.signing_key_normalized

        {
          keys: [
            signing_key.merge(
              use: 'sig',
              alg: Doorkeeper::OpenidConnect.signing_algorithm
            )
          ]
        }
      end

      def protocol
        Doorkeeper::OpenidConnect.configuration.protocol.call
      end

      def discovery_url_options
        Doorkeeper::OpenidConnect.configuration.discovery_url_options.call(request)
      end

      def discovery_url_default_options
        {
          protocol: protocol
        }
      end

      def issuer
        if Doorkeeper::OpenidConnect.configuration.issuer.respond_to?(:call)
          Doorkeeper::OpenidConnect.configuration.issuer.call(request).to_s
        else
          Doorkeeper::OpenidConnect.configuration.issuer
        end
      end

      %i[authorization token revocation introspection userinfo jwks webfinger].each do |endpoint|
        define_method :"#{endpoint}_url_options" do
          discovery_url_default_options.merge(discovery_url_options[endpoint.to_sym] || {})
        end
      end
    end
  end
end
