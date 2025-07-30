# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin::DatabaseDiagnostics', feature_category: :database do
  include AdminModeHelper

  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }

  shared_examples 'unauthorized request' do
    context 'when user is not an admin' do
      before do
        login_as(user)
      end

      it 'returns 404 response' do
        send_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when admin mode is disabled' do
      before do
        login_as(admin)
      end

      it 'redirects to admin mode enable' do
        send_request

        expect(response).to redirect_to(new_admin_session_path)
      end
    end
  end

  describe 'GET /admin/database_diagnostics' do
    subject(:send_request) do
      get admin_database_diagnostics_path
    end

    it_behaves_like 'unauthorized request'

    context 'when admin mode is enabled', :enable_admin_mode do
      before do
        login_as(admin)
      end

      it 'returns 200 response' do
        send_request

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'POST /admin/database_diagnostics/run_collation_check' do
    subject(:send_request) do
      post run_collation_check_admin_database_diagnostics_path(format: :json)
    end

    it_behaves_like 'unauthorized request'

    context 'when admin mode is enabled', :enable_admin_mode do
      before do
        login_as(admin)
      end

      it 'returns 200 response and schedules the worker' do
        expect(::Database::CollationCheckerWorker).to receive(:perform_async).and_return('job_id')

        send_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include('status' => 'scheduled', 'job_id' => 'job_id')
      end
    end
  end

  describe 'GET /admin/database_diagnostics/collation_check_results' do
    subject(:send_request) do
      get collation_check_results_admin_database_diagnostics_path(format: :json)
    end

    it_behaves_like 'unauthorized request'

    context 'when admin mode is enabled', :enable_admin_mode do
      before do
        login_as(admin)
      end

      context 'when results are available' do
        let(:results) do
          {
            metadata: { last_run_at: Time.current.iso8601 },
            databases: {
              main: {
                collation_mismatches: [],
                corrupted_indexes: []
              }
            }
          }
        end

        it 'returns 200 response with the results' do
          allow(Rails.cache).to receive(:read)
          expect(Rails.cache).to receive(:read)
            .with(::Database::CollationCheckerWorker::COLLATION_CHECK_CACHE_KEY)
            .and_return(results.to_json)

          send_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to include('metadata', 'databases')
        end
      end

      context 'when no results are available' do
        it 'returns 404 response' do
          send_request

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response).to include('error' => 'No results available yet')
        end
      end
    end
  end
end
