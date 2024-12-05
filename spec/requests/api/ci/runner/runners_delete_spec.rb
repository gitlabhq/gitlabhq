# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Runner, :clean_gitlab_redis_shared_state, feature_category: :fleet_visibility do
  include StubGitlabCalls
  include RedisHelpers
  include WorkhorseHelpers

  before do
    stub_feature_flags(ci_enable_live_trace: true)
    stub_gitlab_calls
    allow_next_instance_of(::Ci::Runner) { |runner| allow(runner).to receive(:cache_attributes) }
  end

  describe '/api/v4/runners' do
    let(:params) { nil }
    let(:registration_token) { 'abcdefg123456' }

    before do
      stub_application_setting(runners_registration_token: registration_token)
    end

    subject(:perform_request) { delete api('/runners'), params: params }

    describe 'DELETE /api/v4/runners' do
      it_behaves_like 'runner migrations backoff' do
        let(:request) { delete api('/runners') }
      end

      context 'when no token is provided' do
        it 'returns 400 error' do
          perform_request

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when invalid token is provided' do
        let(:params) do
          { token: 'invalid' }
        end

        it 'returns 403 error' do
          perform_request

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when valid token is provided' do
        let!(:runner) { create(:ci_runner, *args) }
        let(:args) { [] }
        let(:params) { { token: runner.token } }

        it 'deletes runner' do
          expect { perform_request }.to change { ::Ci::Runner.count }.by(-1)

          expect(response).to have_gitlab_http_status(:no_content)
        end

        it 'does not create missing runner manager' do
          query = ActiveRecord::QueryRecorder.new { perform_request }

          expect(query.log.select { |cmd| cmd.include?(::Ci::RunnerManager.table_name) }).to be_empty
        end

        it 'does not modify any record' do
          query = ActiveRecord::QueryRecorder.new { perform_request }

          expect(query.log.select { |cmd| cmd.include?('UPDATE') }).to be_empty
        end

        context 'with associated runner manager' do
          let(:args) { :with_runner_manager }

          it 'deletes runner and associated manager' do
            expect { perform_request }
              .to change { ::Ci::Runner.count }.by(-1)
              .and change { ::Ci::RunnerManager.count }.by(-1)

            expect(response).to have_gitlab_http_status(:no_content)
          end

          it 'does not modify any record' do
            query = ActiveRecord::QueryRecorder.new { perform_request }

            expect(query.log.select { |cmd| cmd.include?('UPDATE') }).to be_empty
          end
        end

        it_behaves_like '412 response' do
          let(:request) { api('/runners') }
          let(:params) { { token: runner.token } }
        end

        it_behaves_like 'storing arguments in the application context for the API' do
          let(:expected_params) { { client_id: "runner/#{runner.id}" } }
        end
      end
    end
  end

  describe '/api/v4/runners/managers' do
    describe 'DELETE /api/v4/runners/managers' do
      subject(:delete_request) { delete api('/runners/managers'), params: delete_params }

      context 'with created runner' do
        let!(:runner) { create(:ci_runner, :with_runner_manager, registration_type: :authenticated_user) }
        let(:delete_params) do
          { token: runner.token, system_id: runner.runner_managers.first.system_xid }
        end

        it 'deletes runner manager' do
          expect do
            delete_request

            expect(response).to have_gitlab_http_status(:no_content)
          end.to change { runner.runner_managers.count }.from(1).to(0)
            .and not_change { ::Ci::Runner.count }.from(1)
        end

        it_behaves_like '412 response' do
          let(:request) { api('/runners/managers') }
          let(:params) { delete_params }
        end

        it_behaves_like 'storing arguments in the application context for the API' do
          let(:expected_params) { { client_id: "runner/#{runner.id}" } }
        end

        context 'with unknown system_id' do
          let(:delete_params) { { token: runner.token, system_id: 'unknown_system_id' } }

          it 'returns 404 error' do
            delete_request

            expect(response).to have_gitlab_http_status(:not_found)
            expect(response.body).to include('Runner manager not found')
            expect(::Ci::Runner.count).to eq(1)
          end
        end

        context 'without system_id' do
          let(:delete_params) { { token: runner.token } }

          it 'does not delete runner manager nor runner' do
            delete_request

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end

        context 'when no token is provided' do
          let(:delete_params) { { system_id: runner.runner_managers.first.system_xid } }

          it 'returns 400 error' do
            delete_request

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end

        context 'when invalid token is provided' do
          let(:delete_params) { { token: 'invalid', system_id: runner.runner_managers.first.system_xid } }

          it 'returns 403 error' do
            delete_request

            expect(response).to have_gitlab_http_status(:forbidden)
          end
        end
      end
    end
  end
end
