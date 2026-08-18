# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::FeatureLibraryController, feature_category: :onboarding do
  let_it_be(:user) { create(:user) }

  describe 'GET /-/onboarding/feature_library/search', :clean_gitlab_redis_rate_limiting do
    context 'when signed in' do
      before do
        sign_in(user)
      end

      it 'returns 200 with a non-empty ids array for a valid request', :aggregate_failures do
        get onboarding_feature_library_search_path, params: { query: 'pr', panel: 'project' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['ids']).to be_an(Array).and include('project_merge_request_list')
      end

      context 'with an invalid panel' do
        it 'returns an empty ids array', :aggregate_failures do
          get onboarding_feature_library_search_path, params: { query: 'pr', panel: 'invalid' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['ids']).to eq([])
        end
      end

      context 'when the query parameter is missing' do
        it 'returns an empty ids array', :aggregate_failures do
          get onboarding_feature_library_search_path, params: { panel: 'project' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['ids']).to eq([])
        end
      end

      context 'when the rate limit is exceeded' do
        before do
          allow(Gitlab::ApplicationRateLimiter)
            .to receive(:throttled_request?)
            .with(anything, anything, :feature_library_search, scope: user)
            .and_return(true)
        end

        it 'returns 429 with a JSON error message', :aggregate_failures do
          get onboarding_feature_library_search_path, params: { query: 'pr', panel: 'project' }

          expect(response).to have_gitlab_http_status(:too_many_requests)
          expect(json_response['error']).to be_present
        end
      end

      context 'when the query exceeds MAX_QUERY_LENGTH' do
        let(:long_query) { 'x' * (described_class::MAX_QUERY_LENGTH + 50) }

        it 'truncates the query to MAX_QUERY_LENGTH before searching' do
          expect(Onboarding::FeatureLibrary::FeatureMatchService)
            .to receive(:new)
            .with(a_hash_including(query: 'x' * described_class::MAX_QUERY_LENGTH, panel: 'project'))
            .and_call_original

          get onboarding_feature_library_search_path, params: { query: long_query, panel: 'project' }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when the query is exactly MAX_QUERY_LENGTH' do
        let(:max_query) { 'x' * described_class::MAX_QUERY_LENGTH }

        it 'passes the query through unchanged' do
          expect(Onboarding::FeatureLibrary::FeatureMatchService)
            .to receive(:new)
            .with(a_hash_including(query: max_query, panel: 'project'))
            .and_call_original

          get onboarding_feature_library_search_path, params: { query: max_query, panel: 'project' }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'when not authenticated' do
        before do
          sign_out(user)
        end

        it 'redirects to sign in' do
          get onboarding_feature_library_search_path, params: { query: 'pr', panel: 'project' }

          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end
  end

  describe 'GET /-/onboarding/feature_library/ai_search', :clean_gitlab_redis_rate_limiting do
    context 'when signed in' do
      before do
        sign_in(user)
      end

      it 'returns 404 when the feature_discovery_gemini_search flag is disabled' do
        stub_feature_flags(feature_discovery_gemini_search: false)

        get onboarding_feature_library_ai_search_path, params: { query: 'pr', panel: 'project' }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when not authenticated' do
      it 'redirects to sign in' do
        get onboarding_feature_library_ai_search_path, params: { query: 'pr', panel: 'project' }

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
