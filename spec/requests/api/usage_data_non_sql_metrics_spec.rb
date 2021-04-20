# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::UsageDataNonSqlMetrics do
  include UsageDataHelpers

  let_it_be(:admin) { create(:user, admin: true) }
  let_it_be(:user) { create(:user) }

  before do
    stub_usage_data_connections
  end

  describe 'GET /usage_data/non_sql_metrics' do
    let(:endpoint) { '/usage_data/non_sql_metrics' }

    context 'with authentication' do
      before do
        stub_feature_flags(usage_data_non_sql_metrics: true)
      end

      it 'returns non sql metrics if user is admin' do
        get api(endpoint, admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['counts']).to be_a(Hash)
      end

      it 'returns forbidden if user is not admin' do
        get api(endpoint, user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'without authentication' do
      before do
        stub_feature_flags(usage_data_non_sql_metrics: true)
      end

      it 'returns unauthorized' do
        get api(endpoint)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when feature_flag is disabled' do
      before do
        stub_feature_flags(usage_data_non_sql_metrics: false)
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
