# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Integrations::Slack::Interactions, feature_category: :integrations do
  describe 'POST /integrations/slack/interactions' do
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

    subject { post api('/integrations/slack/interactions'), params: params, headers: headers }

    it_behaves_like 'Slack request verification'

    context 'when type param is unknown' do
      let(:payload) do
        { type: 'unknown_type' }
      end

      it 'generates a tracked error' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).once

        subject

        expect(response).to have_gitlab_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context 'when event.type param is view_closed' do
      let(:payload) do
        {
          type: 'view_closed',
          team_id: slack_installation.team_id,
          event: {
            type: 'view_closed',
            user: 'U0123ABCDEF'
          }
        }
      end

      it 'calls the Slack Interactivity Service' do
        expect_next_instance_of(::Integrations::SlackInteractionService) do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.success)
        end

        subject

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
