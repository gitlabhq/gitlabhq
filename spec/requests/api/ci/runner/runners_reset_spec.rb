# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ci::Runner, :clean_gitlab_redis_shared_state, feature_category: :fleet_visibility do
  include StubGitlabCalls
  include RedisHelpers
  include WorkhorseHelpers

  before do
    stub_feature_flags(ci_enable_live_trace: true)
    stub_gitlab_calls
    stub_application_setting(valid_runner_registrars: ApplicationSetting::VALID_RUNNER_REGISTRAR_TYPES)
  end

  let_it_be(:group_settings) { create(:namespace_settings, runner_token_expiration_interval: 5.days.to_i) }
  let_it_be(:group) { create(:group, namespace_settings: group_settings) }
  let_it_be(:instance_runner, reload: true) { create(:ci_runner, :instance) }
  let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group], token_expires_at: 1.day.from_now) }

  describe 'POST /runners/reset_authentication_token', :freeze_time do
    it_behaves_like 'runner migrations backoff' do
      let(:request) { post api("/runners/reset_authentication_token") }
    end

    context 'current token provided' do
      it "resets authentication token when token doesn't have an expiration" do
        expect do
          post api("/runners/reset_authentication_token"), params: { token: instance_runner.reload.token }

          expect(response).to have_gitlab_http_status(:success)
          expect(json_response).to eq({ 'token' => instance_runner.reload.token, 'token_expires_at' => nil })
          expect(instance_runner.reload.token_expires_at).to be_nil
        end.to change { instance_runner.reload.token }
      end

      it 'resets authentication token when token is not expired' do
        expect do
          post api("/runners/reset_authentication_token"), params: { token: group_runner.reload.token }

          group_runner.reload
          expect(response).to have_gitlab_http_status(:success)
          expect(json_response).to eq({ 'token' => group_runner.token, 'token_expires_at' => group_runner.token_expires_at.iso8601(3) })
          expect(group_runner.token_expires_at).to eq(5.days.from_now)
        end.to change { group_runner.reload.token }
      end

      it 'does not reset authentication token when token is expired' do
        expect do
          instance_runner.update!(token_expires_at: 1.day.ago)
          post api("/runners/reset_authentication_token"), params: { token: instance_runner.reload.token }

          expect(response).to have_gitlab_http_status(:forbidden)
          instance_runner.update!(token_expires_at: nil)
        end.not_to change { instance_runner.reload.token }
      end
    end

    context 'wrong current token provided' do
      it 'does not reset authentication token' do
        expect do
          post api("/runners/reset_authentication_token"), params: { token: 'garbage' }

          expect(response).to have_gitlab_http_status(:forbidden)
        end.not_to change { instance_runner.reload.token }
      end
    end
  end
end
