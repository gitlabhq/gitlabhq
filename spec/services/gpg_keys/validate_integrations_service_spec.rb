# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GpgKeys::ValidateIntegrationsService, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }

  let(:gpg_key) { build(:gpg_key, user: user) }

  subject(:service) { described_class.new(gpg_key) }

  it 'returns true' do
    expect(service.execute).to eq(true)
  end

  context 'when key is invalid' do
    it 'returns false' do
      gpg_key.key = ''

      expect(service.execute).to eq(false)
    end
  end

  context 'when BeyondIdentity integration is not activated' do
    let_it_be(:integration) { create(:beyond_identity_integration, active: false) }

    it 'return false' do
      expect(::Gitlab::BeyondIdentity::Client).not_to receive(:new)

      expect(service.execute).to eq(true)
    end
  end

  context 'when BeyondIdentity integration is activated' do
    let_it_be(:integration) { create(:beyond_identity_integration) }

    it 'returns true on successful check' do
      expect_next_instance_of(::Gitlab::BeyondIdentity::Client) do |instance|
        expect(instance).to receive(:execute).with(
          { key_id: 'CCFBE19F00AC8B1D', committer_email: user.email }
        )
      end

      expect(service.execute).to eq(true)
      expect(gpg_key.externally_verified).to be_truthy
    end

    it 'returns false and sets an error on unsuccessful check' do
      error = 'service error'

      expect_next_instance_of(::Gitlab::BeyondIdentity::Client) do |instance|
        expect(instance).to receive(:execute).with(
          { key_id: 'CCFBE19F00AC8B1D', committer_email: user.email }
        ).and_raise(::Gitlab::BeyondIdentity::Client::Error.new(error))
      end

      expect(service.execute).to eq(false)
      expect(gpg_key.errors.full_messages).to eq(['BeyondIdentity: service error'])
    end
  end
end
