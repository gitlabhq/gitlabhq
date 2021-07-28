# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::Mailgun::ProcessWebhookService do
  describe '#execute', :aggregate_failures do
    let_it_be(:member) { create(:project_member, :invited) }

    let(:raw_invite_token) { member.raw_invite_token }
    let(:payload) { { 'user-variables' => { ::Members::Mailgun::INVITE_EMAIL_TOKEN_KEY => raw_invite_token } } }

    subject(:service) { described_class.new(payload).execute }

    it 'marks the member invite email success as false' do
      expect(Gitlab::AppLogger).to receive(:info).with(/^UPDATED MEMBER INVITE_EMAIL_SUCCESS/).and_call_original

      expect { service }.to change { member.reload.invite_email_success }.from(true).to(false)
    end

    context 'when member can not be found' do
      let(:raw_invite_token) { '_foobar_' }

      it 'does not change member status' do
        expect(Gitlab::AppLogger).not_to receive(:info).with(/^UPDATED MEMBER INVITE_EMAIL_SUCCESS/)

        expect { service }.not_to change { member.reload.invite_email_success }
      end
    end

    context 'when invite token is not found in payload' do
      let(:payload) { {} }

      it 'does not change member status and logs an error' do
        expect(Gitlab::AppLogger).not_to receive(:info).with(/^UPDATED MEMBER INVITE_EMAIL_SUCCESS/)
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          an_instance_of(described_class::ProcessWebhookServiceError))

        expect { service }.not_to change { member.reload.invite_email_success }
      end
    end
  end
end
