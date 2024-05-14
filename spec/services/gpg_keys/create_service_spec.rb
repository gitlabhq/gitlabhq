# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GpgKeys::CreateService, feature_category: :source_code_management do
  let(:user) { create(:user) }
  let(:params) { attributes_for(:gpg_key) }

  subject { described_class.new(user, params) }

  context 'notification', :mailer do
    it 'sends a notification' do
      perform_enqueued_jobs do
        subject.execute
      end
      should_email(user)
    end
  end

  it 'creates a gpg key' do
    expect { subject.execute }.to change { user.gpg_keys.where(params).count }.by(1)
  end

  context 'when the public key contains subkeys' do
    let(:params) { attributes_for(:gpg_key_with_subkeys) }

    it 'generates the gpg subkeys' do
      gpg_key = subject.execute

      expect(gpg_key.subkeys.count).to eq(2)
    end
  end

  context 'invalid key' do
    let(:params) { {} }

    it 'returns an invalid key' do
      expect(GpgKeys::ValidateIntegrationsService).not_to receive(:new)

      gpg_key = subject.execute

      expect(gpg_key).not_to be_persisted
    end
  end
end
