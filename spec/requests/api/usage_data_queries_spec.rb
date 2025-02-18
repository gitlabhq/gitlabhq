# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::UsageDataQueries, :aggregate_failures, feature_category: :service_ping do
  include UsageDataHelpers

  let!(:admin) { create(:user, admin: true) }
  let!(:user) { create(:user) }

  before do
    stub_usage_data_connections
    stub_database_flavor_check
  end

  describe 'GET /usage_data/usage_data_queries', :with_license do
    let(:endpoint) { '/usage_data/queries' }

    context 'with authentication' do
      before do
        stub_feature_flags(usage_data_queries_api: true)
      end

      it_behaves_like 'GET request permissions for admin mode' do
        let(:path) { endpoint }
      end

      context "when user is admin" do
        context "with an available NonSqlServicePing entry" do
          it 'returns non sql metrics' do
            query = 'SELECT COUNT("users"."id") FROM "users" WHERE active = 1'
            create :queries_service_ping, payload: { active_user_count: query }

            get api(endpoint, admin, admin_mode: true)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['active_user_count']).to start_with('SELECT COUNT("users"."id") FROM "users"')
          end
        end

        context "with no recent NonSqlServicePing entry" do
          it 'returns default response' do
            create :queries_service_ping, payload: { counts: { abc: 12 } }, created_at: 2.weeks.ago

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
        get api(endpoint, admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns forbidden for non-admin' do
        get api(endpoint, user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when querying sql metrics', type: :task do
      let(:file) { Rails.root.join('tmp', 'test', 'sql_metrics_queries.json') }
      let(:time) { Time.utc(2021, 1, 1) }

      before do
        Rake.application.rake_require 'tasks/gitlab/usage_data'

        run_rake_task('gitlab:usage_data:generate_sql_metrics_queries')
      end

      after do
        FileUtils.rm_rf(file)
      end

      it 'matches the generated query' do
        data = Gitlab::Json.parse(File.read(file))

        create :queries_service_ping, payload: data, created_at: time - 2.days

        travel_to(time) do
          get api(endpoint, admin, admin_mode: true)
        end

        expect(
          json_response['counts_weekly'].except('aggregated_metrics')
        ).to eq(data['counts_weekly'].except('aggregated_metrics'))

        expect(json_response['counts']).to eq(data['counts'])
        expect(json_response['active_user_count']).to eq(data['active_user_count'])
        expect(json_response['usage_activity_by_stage']).to eq(data['usage_activity_by_stage'])
        expect(json_response['usage_activity_by_stage_monthly']).to eq(data['usage_activity_by_stage_monthly'])
      end
    end
  end
end
