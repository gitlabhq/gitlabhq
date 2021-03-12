# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Runner, :clean_gitlab_redis_shared_state do
  include StubGitlabCalls
  include RedisHelpers
  include WorkhorseHelpers

  let(:registration_token) { 'abcdefg123456' }

  before do
    stub_feature_flags(ci_enable_live_trace: true)
    stub_gitlab_calls
    stub_application_setting(runners_registration_token: registration_token)
    allow_any_instance_of(::Ci::Runner).to receive(:cache_attributes)
  end

  describe '/api/v4/runners' do
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

        it_behaves_like 'storing arguments in the application context' do
          let(:expected_params) { { client_id: "runner/#{runner.id}" } }
        end
      end
    end
  end
end
