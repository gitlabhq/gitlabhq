# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::UsageDataNonSqlMetrics, :aggregate_failures, feature_category: :service_ping do
  include UsageDataHelpers

  let_it_be(:admin) { create(:user, admin: true) }
  let_it_be(:user) { create(:user) }

  before do
    stub_usage_data_connections
  end

  describe 'GET /usage_data/non_sql_metrics', :with_license do
    let(:endpoint) { '/usage_data/non_sql_metrics' }

    context 'with authentication' do
      before do
        stub_feature_flags(usage_data_non_sql_metrics: true)
        stub_database_flavor_check
      end

      it_behaves_like 'GET request permissions for admin mode' do
        let(:path) { endpoint }
      end

      context "when user is admin" do
        context "with an available NonSqlServicePing entry" do
          it 'returns non sql metrics' do
            create :non_sql_service_ping, payload: { counts: { abc: 12 } }

            get api(endpoint, admin, admin_mode: true)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['counts']).to be_a(Hash)
          end
        end

        context "with no recent NonSqlServicePing entry" do
          it 'returns default response' do
            create :non_sql_service_ping, payload: { counts: { abc: 12 } }, created_at: 2.weeks.ago

            get api(endpoint, admin, admin_mode: true)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response).to eq({})
          end
        end
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
        get api(endpoint, admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns forbidden for non-admin' do
        get api(endpoint, user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
