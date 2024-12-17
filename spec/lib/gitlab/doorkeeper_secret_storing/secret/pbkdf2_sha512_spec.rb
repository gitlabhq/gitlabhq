# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DoorkeeperSecretStoring::Secret::Pbkdf2Sha512 do
  describe '.transform_secret' do
    let(:plaintext_secret) { 'CzOBzBfU9F-HvsqfTaTXF4ivuuxYZuv3BoAK4pnvmyw' }

    it 'generates a PBKDF2+SHA512 hashed value in the correct format' do
      expect(described_class.transform_secret(plaintext_secret))
        .to eq("$pbkdf2-sha512$20000$$.c0G5XJVEew1TyeJk5TrkvB0VyOaTmDzPrsdNRED9vVeZlSyuG3G90F0ow23zUCiWKAVwmNnR/ceh.nJG3MdpQ")
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

  describe '.secret_matches?' do
    it "match by hashing the input if the stored value is hashed" do
      plain_secret = 'plain_secret'
      stored_value = '$pbkdf2-sha512$20000$$/BwQRdwSpL16xkQhstavh7nvA5avCP7.4n9LLKe9AupgJDeA7M5xOAvG3N3E5XbRyGWWBbbr.BsojPVWzd1Sqg'
      expect(described_class.secret_matches?(plain_secret, stored_value)).to be true
    end
  end
end
