# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Mailgun::WebhookProcessors::MemberInvites do
  describe '#execute', :aggregate_failures do
    let_it_be(:member) { create(:project_member, :invited) }

    let(:raw_invite_token) { member.raw_invite_token }
    let(:payload) do
      {
        'event' => 'failed',
        'severity' => 'permanent',
        'tags' => [Members::Mailgun::INVITE_EMAIL_TAG],
        'user-variables' => { ::Members::Mailgun::INVITE_EMAIL_TOKEN_KEY => raw_invite_token }
      }
    end

    subject(:service) { described_class.new(payload).execute }

    it 'marks the member invite email success as false' do
      expect(Gitlab::AppLogger).to receive(:info).with(
        message: /^UPDATED MEMBER INVITE_EMAIL_SUCCESS/,
        event: 'updated_member_invite_email_success'
      ).and_call_original

      expect { service }.to change { member.reload.invite_email_success }.from(true).to(false)
    end

    context 'when invite token is not found in payload' do
      before do
        payload.delete('user-variables')
      end

      it 'does not change member status and logs an error' do
        expect(Gitlab::AppLogger).not_to receive(:info)
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          an_instance_of(described_class::ProcessWebhookServiceError))

        expect { service }.not_to change { member.reload.invite_email_success }
      end
    end

    shared_examples 'does nothing' do
      it 'does not change member status' do
        expect(Gitlab::AppLogger).not_to receive(:info)

        expect { service }.not_to change { member.reload.invite_email_success }
      end
    end

    context 'when member can not be found' do
      let(:raw_invite_token) { '_foobar_' }

      it_behaves_like 'does nothing'
    end

    context 'when failure is temporary' do
      before do
        payload['severity'] = 'temporary'
      end

      it_behaves_like 'does nothing'
    end

    context 'when email is not a member invite' do
      before do
        payload.delete('tags')
      end

      it_behaves_like 'does nothing'
    end
  end
end
