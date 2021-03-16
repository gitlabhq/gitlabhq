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
    describe 'POST /api/v4/runners/verify' do
      let(:runner) { create(:ci_runner) }

      context 'when no token is provided' do
        it 'returns 400 error' do
          post api('/runners/verify')

          expect(response).to have_gitlab_http_status :bad_request
        end
      end

      context 'when invalid token is provided' do
        it 'returns 403 error' do
          post api('/runners/verify'), params: { token: 'invalid-token' }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when valid token is provided' do
        subject { post api('/runners/verify'), params: { token: runner.token } }

        it 'verifies Runner credentials' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
        end

        it_behaves_like 'storing arguments in the application context' do
          let(:expected_params) { { client_id: "runner/#{runner.id}" } }
        end
      end
    end
  end
end
