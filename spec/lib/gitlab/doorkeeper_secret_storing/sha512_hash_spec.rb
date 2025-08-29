# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DoorkeeperSecretStoring::Sha512Hash, feature_category: :system_access do
  let(:plaintext_token) { 'CzOBzBfU9F-HvsqfTaTXF4ivuuxYZuv3BoAK4pnvmyw' }

  describe '.transform_secret' do
    it 'generates a SHA512 hashed value in the correct format' do
      expect(described_class.transform_secret(plaintext_token))
        .to eq("6d99aa9e8c21b9d06b3c4c453dc2446a96385a7c1f7cc0d2c5ca5c1e24e" \
          "4269f0c941167f5e2e8bb6376400728a2a7013c0c128183456372d64e8e973efafd49")
    end
  end

  context 'when feature flag is disabled' do
    before do
      stub_feature_flags(sha512_oauth: false)
    end

    it 'generates a PBKDF2+SHA512 hashed value in the correct format' do
      expected_hash = "$pbkdf2-sha512$20000$$" \
        ".c0G5XJVEew1TyeJk5TrkvB0VyOaTmDzPrsdNRED9vVeZlSyuG3G90F0ow23zUCiWKAVwmNnR/ceh.nJG3MdpQ"
      expect(described_class.transform_secret(plaintext_token))
        .to eq(expected_hash)
    end
  end
end
