# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Runner, :clean_gitlab_redis_shared_state, feature_category: :runner_fleet do
  include StubGitlabCalls
  include RedisHelpers
  include WorkhorseHelpers

  before do
    stub_feature_flags(ci_enable_live_trace: true)
    stub_gitlab_calls
    allow_next_instance_of(::Ci::Runner) { |runner| allow(runner).to receive(:cache_attributes) }
  end

  describe '/api/v4/runners' do
    let(:registration_token) { 'abcdefg123456' }

    before do
      stub_application_setting(runners_registration_token: registration_token)
    end

    describe 'DELETE /api/v4/runners' do
      context 'when no token is provided' do
        it 'returns 400 error' do
          delete api('/runners')

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when invalid token is provided' do
        it 'returns 403 error' do
          delete api('/runners'), params: { token: 'invalid' }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when valid token is provided' do
        let(:runner) { create(:ci_runner) }

        subject { delete api('/runners'), params: { token: runner.token } }

        it 'deletes Runner' do
          subject

          expect(response).to have_gitlab_http_status(:no_content)
          expect(::Ci::Runner.count).to eq(0)
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

        context 'with matching system_id' do
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

      context 'when valid token is provided' do
        context 'with created runner' do
          let!(:runner) { create(:ci_runner, :with_runner_manager, registration_type: :authenticated_user) }

          context 'with matching system_id' do
            let(:delete_params) { { token: runner.token, system_id: runner.runner_managers.first.system_xid } }

            it 'deletes runner manager' do
              expect do
                delete_request

                expect(response).to have_gitlab_http_status(:no_content)
              end.to change { runner.runner_managers.count }.from(1).to(0)

              expect(::Ci::Runner.count).to eq(1)
            end

            it_behaves_like '412 response' do
              let(:request) { api('/runners/managers') }
              let(:params) { delete_params }
            end

            it_behaves_like 'storing arguments in the application context for the API' do
              let(:expected_params) { { client_id: "runner/#{runner.id}" } }
            end
          end

          context 'with unknown system_id' do
            let(:delete_params) { { token: runner.token, system_id: 'unknown_system_id' } }

            it 'returns 404 error' do
              delete_request

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end

          context 'without system_id' do
            let(:delete_params) { { token: runner.token } }

            it 'does not delete runner manager nor runner' do
              delete_request

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end
        end
      end
    end
  end
end
