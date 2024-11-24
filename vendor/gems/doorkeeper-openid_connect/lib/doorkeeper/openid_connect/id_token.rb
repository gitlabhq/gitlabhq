# frozen_string_literal: true

module Doorkeeper
  module OpenidConnect
    class IdToken
      include ActiveModel::Validations

      attr_reader :nonce

      def initialize(access_token, nonce = nil)
        @access_token = access_token
        @nonce = nonce
        @resource_owner = Doorkeeper::OpenidConnect.configuration.resource_owner_from_access_token.call(access_token)
        @issued_at = Time.zone.now
      end

      def claims
        {
          iss: issuer,
          sub: subject,
          aud: audience,
          exp: expiration,
          iat: issued_at,
          nonce: nonce,
          auth_time: auth_time
        }.merge ClaimsBuilder.generate(@access_token, :id_token)
      end

      def as_json(*_)
        claims.reject { |_, value| value.nil? || value == '' }
      end

      def as_jws_token
        ::JWT.encode(as_json,
          Doorkeeper::OpenidConnect.signing_key.keypair,
          Doorkeeper::OpenidConnect.signing_algorithm.to_s,
          { typ: 'JWT', kid: Doorkeeper::OpenidConnect.signing_key.kid }
        ).to_s
      end

      private

      def issuer
        if Doorkeeper::OpenidConnect.configuration.issuer.respond_to?(:call)
          Doorkeeper::OpenidConnect.configuration.issuer.call(@resource_owner, @access_token.application).to_s
        else
          Doorkeeper::OpenidConnect.configuration.issuer
        end
      end

      def subject
        Doorkeeper::OpenidConnect.configuration.subject.call(@resource_owner, @access_token.application).to_s
      end

      def audience
        @access_token.application.try(:uid)
      end

      def expiration
        (@issued_at.utc + Doorkeeper::OpenidConnect.configuration.expiration).to_i
      end

      def issued_at
        @issued_at.utc.to_i
      end

      def auth_time
        Doorkeeper::OpenidConnect.configuration.auth_time_from_resource_owner.call(@resource_owner).try(:to_i)
      end
    end
  end
end
