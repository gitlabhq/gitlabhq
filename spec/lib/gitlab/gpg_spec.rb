require 'rails_helper'

describe Gitlab::Gpg do
  describe '.fingerprints_from_key' do
    it 'returns the fingerprint' do
      expect(
        described_class.fingerprints_from_key(GpgHelpers.public_key)
      ).to eq ['4F4840A503964251CF7D7F5DC728AF10972E97C0']
    end

    it 'returns an empty array when the key is invalid' do
      expect(
        described_class.fingerprints_from_key('bogus')
      ).to eq []
    end
  end

  describe '.add_to_keychain', :gpg do
    it 'stores the key in the keychain' do
      expect(GPGME::Key.find(:public, '4F4840A503964251CF7D7F5DC728AF10972E97C0')).to eq []

      Gitlab::Gpg.add_to_keychain(GpgHelpers.public_key)

      expect(GPGME::Key.find(:public, '4F4840A503964251CF7D7F5DC728AF10972E97C0')).not_to eq []
    end
  end

  describe '.remove_from_keychain', :gpg do
    it 'removes the key from the keychain' do
      Gitlab::Gpg.add_to_keychain(GpgHelpers.public_key)
      expect(GPGME::Key.find(:public, '4F4840A503964251CF7D7F5DC728AF10972E97C0')).not_to eq []

      Gitlab::Gpg.remove_from_keychain('4F4840A503964251CF7D7F5DC728AF10972E97C0')

      expect(GPGME::Key.find(:public, '4F4840A503964251CF7D7F5DC728AF10972E97C0')).to eq []
    end
  end
end
