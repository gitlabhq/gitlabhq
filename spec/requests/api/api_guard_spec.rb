# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::APIGuard, feature_category: :system_access do
  context 'when an AuthenticationError exception is raised in the API call' do
    let(:app) do
      Class.new(API::API)
    end

    [
      [Gitlab::Auth::MissingTokenError, :unauthorized, 'unauthorized'],
      [Gitlab::Auth::TokenNotFoundError, :unauthorized, 'invalid_token'],
      [Gitlab::Auth::ExpiredError, :unauthorized, 'invalid_token'],
      [Gitlab::Auth::RevokedError, :unauthorized, 'invalid_token'],
      [Gitlab::Auth::ImpersonationDisabled, :unauthorized, 'invalid_token'],
      [Gitlab::Auth::InsufficientScopeError, :forbidden, 'insufficient_scope'],
      [Gitlab::Auth::RestrictedLanguageServerClientError, :unauthorized, 'restricted_language_server_client_error'],
      [Gitlab::Auth::DpopValidationError, :unauthorized, 'dpop_error'],
      [Gitlab::Auth::GranularPermissionsError, :forbidden, 'insufficient_granular_scope']
    ].each do |exception_class, status, error|
      it "catches #{exception_class} and responds with #{status} status and an #{error} error" do
        app.get 'willfail' do
          raise exception_class, ['message']
        end

        get api('/willfail')

        expect(response).to have_gitlab_http_status(status)
        expect(json_response['error']).to eq(error)
      end
    end
  end
end
