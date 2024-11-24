# frozen_string_literal: true

module Doorkeeper
  module OpenidConnect
    class UserInfo
      include ActiveModel::Validations

      def initialize(access_token)
        @access_token = access_token
      end

      def claims
        {
          sub: subject
        }.merge ClaimsBuilder.generate(@access_token, :user_info)
      end

      def as_json(*_)
        claims.reject { |_, value| value.nil? || value == '' }
      end

      private

      def subject
        Doorkeeper::OpenidConnect.configuration.subject.call(resource_owner, application).to_s
      end

      def resource_owner
        @resource_owner ||= Doorkeeper::OpenidConnect.configuration.resource_owner_from_access_token.call(@access_token)
      end

      def application
        @application ||= @access_token.application
      end
    end
  end
end
