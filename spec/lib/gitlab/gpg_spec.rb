require 'rails_helper'

describe Gitlab::Gpg do
  describe '.fingerprints_from_key' do
    before do
      # make sure that each method is using the temporary keychain
      expect(described_class).to receive(:using_tmp_keychain).and_call_original
    end

    it 'returns CurrentKeyChain.fingerprints_from_key' do
      expect(Gitlab::Gpg::CurrentKeyChain).to receive(:fingerprints_from_key).with(GpgHelpers::User1.public_key)

      described_class.fingerprints_from_key(GpgHelpers::User1.public_key)
    end
  end

  describe '.primary_keyids_from_key' do
    it 'returns the keyid' do
      expect(
        described_class.primary_keyids_from_key(GpgHelpers::User1.public_key)
      ).to eq [GpgHelpers::User1.primary_keyid]
    end

    it 'returns an empty array when the key is invalid' do
      expect(
        described_class.primary_keyids_from_key('bogus')
      ).to eq []
    end
  end

  describe '.user_infos_from_key' do
    it 'returns the names and emails' do
      user_infos = described_class.user_infos_from_key(GpgHelpers::User1.public_key)
      expect(user_infos).to eq([{
        name: GpgHelpers::User1.names.first,
        email: GpgHelpers::User1.emails.first
      }])
    end

    it 'returns an empty array when the key is invalid' do
      expect(
        described_class.user_infos_from_key('bogus')
      ).to eq []
    end
  end
end

describe Gitlab::Gpg::CurrentKeyChain do
  around do |example|
    Gitlab::Gpg.using_tmp_keychain do
      example.run
    end
  end

  describe '.add' do
    it 'stores the key in the keychain' do
      expect(GPGME::Key.find(:public, GpgHelpers::User1.fingerprint)).to eq []

      described_class.add(GpgHelpers::User1.public_key)

      keys = GPGME::Key.find(:public, GpgHelpers::User1.fingerprint)
      expect(keys.count).to eq 1
      expect(keys.first).to have_attributes(
        email: GpgHelpers::User1.emails.first,
        fingerprint: GpgHelpers::User1.fingerprint
      )
    end
  end

  describe '.fingerprints_from_key' do
    it 'returns the fingerprint' do
      expect(
        described_class.fingerprints_from_key(GpgHelpers::User1.public_key)
      ).to eq [GpgHelpers::User1.fingerprint]
    end

    it 'returns an empty array when the key is invalid' do
      expect(
        described_class.fingerprints_from_key('bogus')
      ).to eq []
    end
  end
end
