# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DoorkeeperSecretStoring::Pbkdf2Sha512, feature_category: :system_access do
  describe '.transform_secret' do
    let(:plaintext_secret) { 'CzOBzBfU9F-HvsqfTaTXF4ivuuxYZuv3BoAK4pnvmyw' }

    it 'generates a PBKDF2+SHA512 hashed value in the correct format' do
      expected_hash = "$pbkdf2-sha512$20000$$" \
        ".c0G5XJVEew1TyeJk5TrkvB0VyOaTmDzPrsdNRED9vVeZlSyuG3G90F0ow23zUCiWKAVwmNnR/ceh.nJG3MdpQ"

      expect(described_class.transform_secret(plaintext_secret)).to eq(expected_hash)
    end
  end

  describe 'STRETCHES' do
    it 'is 20_000' do
      expect(described_class::STRETCHES).to eq(20_000)
    end
  end

  describe 'SALT' do
    it 'is empty' do
      expect(described_class::SALT).to be_empty
    end
  end
end
