# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'receive a permanent failure' do
  describe 'POST /members/mailgun/permanent_failures', :aggregate_failures do
    let_it_be(:member) { create(:project_member, :invited) }

    let(:raw_invite_token) { member.raw_invite_token }
    let(:mailgun_events) { true }
    let(:mailgun_signing_key) { 'abc123' }

    subject(:post_request) { post members_mailgun_permanent_failures_path(standard_params) }

    before do
      stub_application_setting(mailgun_events_enabled: mailgun_events, mailgun_signing_key: mailgun_signing_key)
    end

    it 'marks the member invite email success as false' do
      expect { post_request }.to change { member.reload.invite_email_success }.from(true).to(false)

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'when the change to a member is not made' do
      context 'with incorrect signing key' do
        context 'with incorrect signing key' do
          let(:mailgun_signing_key) { '_foobar_' }

          it 'does not change member status and responds as not_found' do
            expect { post_request }.not_to change { member.reload.invite_email_success }

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'with nil signing key' do
          let(:mailgun_signing_key) { nil }

          it 'does not change member status and responds as not_found' do
            expect { post_request }.not_to change { member.reload.invite_email_success }

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'when the feature is not enabled' do
        let(:mailgun_events) { false }

        it 'does not change member status and responds as expected' do
          expect { post_request }.not_to change { member.reload.invite_email_success }

          expect(response).to have_gitlab_http_status(:not_acceptable)
        end
      end

      context 'when it is not an invite email' do
        before do
          stub_const('::Members::Mailgun::INVITE_EMAIL_TAG', '_foobar_')
        end

        it 'does not change member status and responds as expected' do
          expect { post_request }.not_to change { member.reload.invite_email_success }

          expect(response).to have_gitlab_http_status(:not_acceptable)
        end
      end
    end

    def standard_params
      {
        "signature": {
          "timestamp": "1625056677",
          "token": "eb944d0ace7227667a1b97d2d07276ae51d2b849ed2cfa68f3",
          "signature": "9790cc6686eb70f0b1f869180d906870cdfd496d27fee81da0aa86b9e539e790"
        },
        "event-data": {
          "severity": "permanent",
          "tags": ["invite_email"],
          "timestamp": 1521233195.375624,
          "storage": {
            "url": "_anything_",
            "key": "_anything_"
          },
          "log-level": "error",
          "id": "_anything_",
          "campaigns": [],
          "reason": "suppress-bounce",
          "user-variables": {
            "invite_token": raw_invite_token
          },
          "flags": {
            "is-routed": false,
            "is-authenticated": true,
            "is-system-test": false,
            "is-test-mode": false
          },
          "recipient-domain": "example.com",
          "envelope": {
            "sender": "bob@mg.gitlab.com",
            "transport": "smtp",
            "targets": "alice@example.com"
          },
          "message": {
            "headers": {
              "to": "Alice <alice@example.com>",
              "message-id": "20130503192659.13651.20287@mg.gitlab.com",
              "from": "Bob <bob@mg.gitlab.com>",
              "subject": "Test permanent_fail webhook"
            },
            "attachments": [],
            "size": 111
          },
          "recipient": "alice@example.com",
          "event": "failed",
          "delivery-status": {
            "attempt-no": 1,
            "message": "",
            "code": 605,
            "description": "Not delivering to previously bounced address",
            "session-seconds": 0
          }
        }
      }
    end
  end
end
