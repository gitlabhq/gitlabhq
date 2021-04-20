# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::UsageDataQueries do
  include UsageDataHelpers

  let_it_be(:admin) { create(:user, admin: true) }
  let_it_be(:user) { create(:user) }

  before do
    stub_usage_data_connections
  end

  describe 'GET /usage_data/usage_data_queries' do
    let(:endpoint) { '/usage_data/queries' }

    context 'with authentication' do
      before do
        stub_feature_flags(usage_data_queries_api: true)
      end

      it 'returns queries if user is admin' do
        get api(endpoint, admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['active_user_count']).to start_with('SELECT COUNT("users"."id") FROM "users"')
      end

      it 'returns forbidden if user is not admin' do
        get api(endpoint, user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'without authentication' do
      before do
        stub_feature_flags(usage_data_queries_api: true)
      end

      it 'returns unauthorized' do
        get api(endpoint)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when feature_flag is disabled' do
      before do
        stub_feature_flags(usage_data_queries_api: false)
      end

      it 'returns not_found for admin' do
        get api(endpoint, admin)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns forbidden for non-admin' do
        get api(endpoint, user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
