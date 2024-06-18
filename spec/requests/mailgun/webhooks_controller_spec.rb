# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mailgun::WebhooksController, feature_category: :team_planning do
  let(:mailgun_signing_key) { 'abc123' }
  let(:valid_signature) do
    {
      timestamp: "1625056677",
      token: "eb944d0ace7227667a1b97d2d07276ae51d2b849ed2cfa68f3",
      signature: "9790cc6686eb70f0b1f869180d906870cdfd496d27fee81da0aa86b9e539e790"
    }
  end

  let(:event_data) { {} }

  before do
    stub_application_setting(mailgun_events_enabled: true, mailgun_signing_key: mailgun_signing_key)
  end

  def post_request(override_params = {})
    post mailgun_webhooks_path, params: standard_params.merge(override_params)
  end

  describe '#process_webhook' do
    it 'returns 406 when integration is not enabled' do
      stub_application_setting(mailgun_events_enabled: false)

      post_request

      expect(response).to have_gitlab_http_status(:not_acceptable)
    end

    it 'returns 404 when signing key is not configured' do
      stub_application_setting(mailgun_signing_key: nil)

      post_request

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 404 when signature invalid' do
      post_request(
        'signature' => valid_signature.merge('signature' => 'xxx')
      )

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 200 when signature is valid' do
      post_request

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  context 'invite email failures' do
    let_it_be(:member) { create(:project_member, :invited) }

    let(:event_data) do
      {
        event: 'failed',
        severity: 'permanent',
        tags: [Members::Mailgun::INVITE_EMAIL_TAG],
        'user-variables': {
          Members::Mailgun::INVITE_EMAIL_TOKEN_KEY => member.raw_invite_token
        }
      }
    end

    it 'marks the member invite email success as false' do
      expect { post_request }.to change { member.reload.invite_email_success }.from(true).to(false)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'supports legacy URL' do
      expect do
        post members_mailgun_permanent_failures_path, params: {
          'signature' => valid_signature,
          'event-data' => event_data
        }
      end.to change { member.reload.invite_email_success }.from(true).to(false)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'does not change the invite status if failure is temporary' do
      expect do
        post_request({ 'event-data' => event_data.merge(severity: 'temporary') })
      end.not_to change { member.reload.invite_email_success }

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  def standard_params
    {
      signature: valid_signature,
      "event-data": {
        severity: "permanent",
        tags: ["invite_email"],
        timestamp: 1521233195.375624,
        storage: {
          url: "_anything_",
          key: "_anything_"
        },
        "log-level": "error",
        id: "_anything_",
        campaigns: [],
        reason: "suppress-bounce",
        "user-variables": {
          invite_token: '12345'
        },
        flags: {
          "is-routed": false,
          "is-authenticated": true,
          "is-system-test": false,
          "is-test-mode": false
        },
        "recipient-domain": "example.com",
        envelope: {
          sender: "bob@mg.gitlab.com",
          transport: "smtp",
          targets: "alice@example.com"
        },
        message: {
          headers: {
            to: "Alice <alice@example.com>",
            "message-id": "20130503192659.13651.20287@mg.gitlab.com",
            from: "Bob <bob@mg.gitlab.com>",
            subject: "Test permanent_fail webhook"
          },
          attachments: [],
          size: 111
        },
        recipient: "alice@example.com",
        event: "failed",
        "delivery-status": {
          "attempt-no": 1,
          message: "",
          code: 605,
          description: "Not delivering to previously bounced address",
          "session-seconds": 0
        }
      }.merge(event_data)
    }
  end
end
