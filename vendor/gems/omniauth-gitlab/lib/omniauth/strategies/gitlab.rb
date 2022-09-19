# frozen_string_literal: true

require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class GitLab < OmniAuth::Strategies::OAuth2
      API_SUFFIX_REGEX = %r{/api/v(\d+)/?$}.freeze

      option :client_options, site: 'https://gitlab.com'

      option :redirect_url

      uid { raw_info['id'].to_s }

      info do
        {
          name: raw_info['name'],
          username: raw_info['username'],
          email: raw_info['email'],
          image: raw_info['avatar_url']
        }
      end

      extra do
        { raw_info: raw_info }
      end

      def raw_info
        @raw_info ||= access_token.get(user_endpoint_url).parsed
      end

      def callback_url
        options.redirect_url || (full_host + callback_path)
      end

      private

      def user_endpoint_url
        options.client_options.site.match(API_SUFFIX_REGEX) ? 'user' : 'api/v4/user'
      end
    end
  end
end

OmniAuth.config.add_camelization 'gitlab', 'GitLab'
