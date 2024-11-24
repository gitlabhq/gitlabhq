# frozen_string_literal: true

require 'ostruct'

module Doorkeeper
  module OpenidConnect
    class ClaimsBuilder
      def self.generate(access_token, response)
        resource_owner = Doorkeeper::OpenidConnect.configuration.resource_owner_from_access_token.call(access_token)

        Doorkeeper::OpenidConnect.configuration.claims.to_h.map do |name, claim|
          if access_token.scopes.exists?(claim.scope) && claim.response.include?(response)
            [name, claim.generator.call(resource_owner, access_token.scopes, access_token)]
          end
        end.compact.to_h
      end

      def initialize(&block)
        @claims = OpenStruct.new
        instance_eval(&block)
      end

      def build
        @claims
      end

      def normal_claim(name, response: [:user_info], scope: nil, &block)
        @claims[name] =
          Claims::NormalClaim.new(
            name: name,
            response: response,
            scope: scope,
            generator: block
          )
      end
      alias claim normal_claim
    end
  end
end
