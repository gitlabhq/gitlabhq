# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Integrations::Slack::Options, feature_category: :integrations do
  describe 'POST /integrations/slack/options' do
    let_it_be(:slack_installation) { create(:slack_integration) }

    let(:payload) { {} }
    let(:params) { { payload: Gitlab::Json.dump(payload) } }

    let(:headers) do
      {
        ::API::Integrations::Slack::Request::VERIFICATION_TIMESTAMP_HEADER => Time.current.to_i.to_s,
        ::API::Integrations::Slack::Request::VERIFICATION_SIGNATURE_HEADER => 'mock_verified_signature'
      }
    end

    before do
      allow(ActiveSupport::SecurityUtils).to receive(:secure_compare) do |signature|
        signature == 'mock_verified_signature'
      end

      stub_application_setting(slack_app_signing_secret: 'mock_key')
    end

    subject(:post_to_slack_api) { post api('/integrations/slack/options'), params: params, headers: headers }

    it_behaves_like 'Slack request verification'

    context 'when type param is unknown' do
      let(:payload) do
        { action_id: 'unknown_action' }
      end

      it 'generates a tracked error' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).once

        post_to_slack_api

        expect(response).to have_gitlab_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context 'when action_id param is assignee' do
      let(:payload) do
        {
          action_id: 'assignee'
        }
      end

      it 'calls the Slack Interactivity Service' do
        expect_next_instance_of(::Integrations::SlackOptionService) do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.success)
        end

        post_to_slack_api

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
