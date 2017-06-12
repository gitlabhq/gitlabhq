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
