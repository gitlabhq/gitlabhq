# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Metadata, feature_category: :shared do
  shared_examples_for 'GET /metadata' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        get api(endpoint)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated as user' do
      let(:user) { create(:user) }

      it 'returns the metadata information' do
        get api(endpoint, user)

        expect_metadata
      end
    end

    context 'when authenticated with token' do
      let(:personal_access_token) { create(:personal_access_token, scopes: scopes) }

      context 'with api scope' do
        let(:scopes) { %i[api] }

        it 'returns the metadata information' do
          get api(endpoint, personal_access_token: personal_access_token)

          expect_metadata
        end

        it 'returns "200" response on head requests' do
          head api(endpoint, personal_access_token: personal_access_token)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'with ai_features scope' do
        let(:scopes) { %i[ai_features] }

        it 'returns the metadata information' do
          get api(endpoint, personal_access_token: personal_access_token)

          expect_metadata
        end

        it 'returns "200" response on head requests' do
          head api(endpoint, personal_access_token: personal_access_token)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'with read_user scope' do
        let(:scopes) { %i[read_user] }

        it 'returns the metadata information' do
          get api(endpoint, personal_access_token: personal_access_token)

          expect_metadata
        end

        it 'returns "200" response on head requests' do
          head api(endpoint, personal_access_token: personal_access_token)

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'with neither api, ai_features nor read_user scope' do
        let(:scopes) { %i[read_repository] }

        it 'returns authorization error' do
          get api(endpoint, personal_access_token: personal_access_token)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    def expect_metadata
      aggregate_failures("testing response") do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('public_api/v4/metadata')
      end
    end
  end

  describe 'GET /metadata' do
    let(:endpoint) { '/metadata' }

    include_examples 'GET /metadata'
  end

  describe 'GET /version' do
    let(:endpoint) { '/version' }

    include_examples 'GET /metadata'
  end
end
