require 'spec_helper'

describe Gitlab::BackgroundMigration::CreateGpgKeySubkeysFromGpgKeys, :migration, schema: 20171005130944 do
  context 'when GpgKey exists' do
    let!(:gpg_key) { create(:gpg_key, key: GpgHelpers::User3.public_key) }

    before do
      GpgKeySubkey.destroy_all
    end

    it 'generate the subkeys' do
      expect do
        described_class.new.perform(gpg_key.id)
      end.to change { gpg_key.subkeys.count }.from(0).to(2)
    end

    it 'schedules the signature update worker' do
      expect(InvalidGpgSignatureUpdateWorker).to receive(:perform_async).with(gpg_key.id)

      described_class.new.perform(gpg_key.id)
    end
  end

  context 'when GpgKey does not exist' do
    it 'does not do anything' do
      expect(Gitlab::Gpg).not_to receive(:subkeys_from_key)
      expect(InvalidGpgSignatureUpdateWorker).not_to receive(:perform_async)

      described_class.new.perform(123)
    end
  end
end
