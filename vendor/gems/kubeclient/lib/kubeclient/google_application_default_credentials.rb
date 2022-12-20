# frozen_string_literal: true

module Kubeclient
  # Get a bearer token from the Google's application default credentials.
  class GoogleApplicationDefaultCredentials
    class GoogleDependencyError < LoadError # rubocop:disable Lint/InheritException
    end

    class << self
      def token
        begin
          require 'googleauth'
        rescue LoadError => e
          raise GoogleDependencyError,
                'Error requiring googleauth gem. Kubeclient itself does not include the ' \
                'googleauth gem. To support auth-provider gcp, you must include it in your ' \
                "calling application. Failed with: #{e.message}"
        end

        scopes = [
          'https://www.googleapis.com/auth/cloud-platform',
          'https://www.googleapis.com/auth/userinfo.email'
        ]

        authorization = Google::Auth.get_application_default(scopes)
        authorization.apply({})
        authorization.access_token
      end
    end
  end
end
