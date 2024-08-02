# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GpgKeys::ValidateIntegrationsService, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }

  let(:gpg_key) { build(:gpg_key, user: user) }

  subject(:service) { described_class.new(gpg_key) }

  before do
    gpg_key.valid?
  end

  it 'returns true' do
    expect(service.execute).to eq(true)
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
      expect(gpg_key.externally_verified_at).to be_present
    end

    context 'when the check is unsuccessful' do
      before do
        allow_next_instance_of(::Gitlab::BeyondIdentity::Client) do |instance|
          allow(instance).to receive(:execute).with(
            { key_id: 'CCFBE19F00AC8B1D', committer_email: user.email }
          ).and_raise(::Gitlab::BeyondIdentity::Client::ApiError.new(error_message, error_code))
        end
      end

      context 'when authorization fails' do
        let(:error_message) { 'unauthorized: key is invalid' }
        let(:error_code) { 403 }

        it 'returns false and sets an error' do
          expect(service.execute).to eq(false)
          expect(gpg_key.errors.full_messages).to eq(["BeyondIdentity: #{error_message}"])
          expect(gpg_key.externally_verified).to be_falsey
          expect(gpg_key.externally_verified_at).not_to be_present
        end
      end

      context 'when the key is not found' do
        let(:error_message) { 'gpg key is not found' }
        let(:error_code) { 404 }

        it 'returns true and does not set an error' do
          expect(service.execute).to eq(true)
          expect(gpg_key.errors.full_messages).to eq([])
          expect(gpg_key.externally_verified).to be_falsey
        end
      end
    end
  end
end
