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

  describe '.emails_from_key' do
    it 'returns the emails' do
      expect(
        described_class.emails_from_key(GpgHelpers::User1.public_key)
      ).to eq GpgHelpers::User1.emails
    end

    it 'returns an empty array when the key is invalid' do
      expect(
        described_class.emails_from_key('bogus')
      ).to eq []
    end
  end
end

describe Gitlab::Gpg::CurrentKeyChain, :gpg do
  describe '.add', :gpg do
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
end
