require 'rails_helper'

describe Gitlab::Gpg do
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

  describe '.add_to_keychain', :gpg do
    it 'stores the key in the keychain' do
      expect(GPGME::Key.find(:public, GpgHelpers::User1.fingerprint)).to eq []

      Gitlab::Gpg.add_to_keychain(GpgHelpers::User1.public_key)

      expect(GPGME::Key.find(:public, GpgHelpers::User1.fingerprint)).not_to eq []
    end
  end

  describe '.remove_from_keychain', :gpg do
    it 'removes the key from the keychain' do
      Gitlab::Gpg.add_to_keychain(GpgHelpers::User1.public_key)
      expect(GPGME::Key.find(:public, GpgHelpers::User1.fingerprint)).not_to eq []

      Gitlab::Gpg.remove_from_keychain(GpgHelpers::User1.fingerprint)

      expect(GPGME::Key.find(:public, GpgHelpers::User1.fingerprint)).to eq []
    end
  end
end
