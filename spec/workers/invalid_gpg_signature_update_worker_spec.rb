# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InvalidGpgSignatureUpdateWorker, feature_category: :source_code_management do
  context 'when GpgKey is found' do
    it 'calls NotificationService.new.run' do
      gpg_key = create(:gpg_key)
      invalid_signature_updater = double(:invalid_signature_updater)

      expect(Gitlab::Gpg::InvalidGpgSignatureUpdater).to receive(:new).with(gpg_key).and_return(invalid_signature_updater)
      expect(invalid_signature_updater).to receive(:run)

      described_class.new.perform(gpg_key.id)
    end
  end

  context 'when GpgKey is not found' do
    let(:nonexisting_gpg_key_id) { -1 }

    it 'does not raise errors' do
      expect { described_class.new.perform(nonexisting_gpg_key_id) }.not_to raise_error
    end

    it 'does not call NotificationService.new.run' do
      expect(Gitlab::Gpg::InvalidGpgSignatureUpdater).not_to receive(:new)

      described_class.new.perform(nonexisting_gpg_key_id)
    end
  end
end
