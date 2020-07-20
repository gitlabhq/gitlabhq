# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Version do
  shared_examples_for 'GET /version' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        get api('/version')

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated as user' do
      let(:user) { create(:user) }

      it 'returns the version information' do
        get api('/version', user)

        expect_version
      end
    end

    context 'when authenticated with token' do
      let(:personal_access_token) { create(:personal_access_token, scopes: scopes) }

      context 'with api scope' do
        let(:scopes) { %i(api) }

        it 'returns the version information' do
          get api('/version', personal_access_token: personal_access_token)

          expect_version
        end
      end

      context 'with read_user scope' do
        let(:scopes) { %i(read_user) }

        it 'returns the version information' do
          get api('/version', personal_access_token: personal_access_token)

          expect_version
        end
      end

      context 'with neither api nor read_user scope' do
        let(:scopes) { %i(read_repository) }

        it 'returns authorization error' do
          get api('/version', personal_access_token: personal_access_token)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    def expect_version
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['version']).to eq(Gitlab::VERSION)
      expect(json_response['revision']).to eq(Gitlab.revision)
    end
  end

  context 'with graphql enabled' do
    before do
      stub_feature_flags(graphql: true)
    end

    include_examples 'GET /version'
  end

  context 'with graphql disabled' do
    before do
      stub_feature_flags(graphql: false)
    end

    include_examples 'GET /version'
  end
end
