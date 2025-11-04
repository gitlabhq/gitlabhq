# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::OauthApplication, feature_category: :system_access do
  let(:application) { create(:oauth_application) }

  it 'uses a prefixed secret' do
    expect(application.plaintext_secret).to match(/gloas-\h{64}/)
  end

  it 'allows dynamic scopes' do
    application.scopes = 'api user:*'
    expect(application).to be_valid
  end

  describe '#secret_matches?' do
    let(:plaintext_secret) { 'CzOBzBfU9F-HvsqfTaTXF4ivuuxYZuv3BoAK4pnvmyw' }
    let(:application) { create(:oauth_application, secret: plaintext_secret) }

    it 'returns false when input is nil' do
      expect(application.secret_matches?(nil)).to be false
    end

    it 'matches plain text secret with current strategy' do
      expect(application.secret_matches?(plaintext_secret)).to be true
    end

    it 'matches PBKDF2+SHA512 hashed secret via fallback' do
      hashed = Gitlab::DoorkeeperSecretStoring::Pbkdf2Sha512.transform_secret(plaintext_secret)
      application.update_column(:secret, hashed)
      expect(application.secret_matches?(plaintext_secret)).to be true
    end

    context "with FIPS mode", :fips_mode do
      it 'does not match PBKDF2+SHA512 hashed secret via fallback' do
        hashed = Gitlab::DoorkeeperSecretStoring::Pbkdf2Sha512.transform_secret(plaintext_secret)
        application.update_column(:secret, hashed)
        expect(application.secret_matches?(plaintext_secret)).to be false
      end
    end

    context "with legacy FIPS", :fips_mode do
      before do
        allow(described_class).to receive(:fips_140_3?).and_return(false)
      end

      it 'matches PBKDF2+SHA512 hashed secret via fallback' do
        hashed = Gitlab::DoorkeeperSecretStoring::Pbkdf2Sha512.transform_secret(plaintext_secret)
        application.update_column(:secret, hashed)
        expect(application.secret_matches?(plaintext_secret)).to be true
      end
    end

    it 'matches SHA512 hashed secret' do
      hashed = Gitlab::DoorkeeperSecretStoring::Sha512Hash.transform_secret(plaintext_secret)
      application.update_column(:secret, hashed)
      expect(application.secret_matches?(plaintext_secret)).to be true
    end

    it 'returns false for incorrect secret' do
      expect(application.secret_matches?('wrong_secret')).to be false
    end
  end

  describe '.find_by_fallback_token' do
    let(:plain_secret) { 'CzOBzBfU9F-HvsqfTaTXF4ivuuxYZuv3BoAK4pnvmyw' }
    let(:pbkdf2_secret) { '$pbkdf2-sha512$20000$$.c0G5XJV...' }
    let(:sha512_secret) { 'a' * 128 }
    let(:attr) { :secret }

    context 'when token is already hashed' do
      it 'returns nil for PBKDF2 formatted tokens' do
        expect(described_class.find_by_fallback_token(attr, pbkdf2_secret)).to be_nil
      end

      it 'returns nil for SHA512 formatted tokens (128 hex chars)' do
        expect(described_class.find_by_fallback_token(attr, sha512_secret)).to be_nil
      end
    end

    context 'with actual fallback strategies' do
      let!(:pbkdf2_token) { create(:oauth_application) }
      let!(:sha512_token) { create(:oauth_application) }
      let!(:plain_token) { create(:oauth_application) }

      before do
        allow(described_class).to receive(:upgrade_fallback_value).and_call_original
      end

      it 'finds application stored with PBKDF2 strategy' do
        pbkdf2_hash = Gitlab::DoorkeeperSecretStoring::Pbkdf2Sha512.transform_secret(plain_secret)
        pbkdf2_token.update_column(:secret, pbkdf2_hash)

        result = described_class.find_by_fallback_token(:secret, plain_secret)

        expect(result).to eq(pbkdf2_token)
        expect(described_class).to have_received(:upgrade_fallback_value).with(pbkdf2_token, :secret,
          plain_secret)
      end

      context "with FIPS mode", :fips_mode do
        it 'does not find application stored with PBKDF2 strategy' do
          pbkdf2_hash = Gitlab::DoorkeeperSecretStoring::Pbkdf2Sha512.transform_secret(plain_secret)
          pbkdf2_token.update_column(:secret, pbkdf2_hash)

          result = described_class.find_by_fallback_token(:secret, plain_secret)

          expect(result).not_to eq(pbkdf2_token)
        end
      end

      it 'finds application stored with Plain strategy when SHA512 fails' do
        # Create a different plain secret that won't match any SHA512 token
        different_secret = 'different_plain_token_xyz'
        plain_token.update_column(:secret, different_secret)

        result = described_class.find_by_fallback_token(:secret, different_secret)

        expect(result).to eq(plain_token)
        expect(described_class).to have_received(:upgrade_fallback_value).with(plain_token, :secret,
          different_secret)
      end

      it 'upgrade legacy plain text tokens' do
        described_class.find_by_fallback_token(:secret, plain_token.plaintext_secret)
        sha512_hash = Gitlab::DoorkeeperSecretStoring::Sha512Hash.transform_secret(plain_token.plaintext_secret)
        expect(plain_token.reload.secret).to eq(sha512_hash)
      end

      it 'returns nil when no strategy finds a match' do
        non_existent_secret = 'this_token_does_not_exist_anywhere'

        result = described_class.find_by_fallback_token(:secret, non_existent_secret)

        expect(result).to be_nil
        expect(described_class).not_to have_received(:upgrade_fallback_value)
      end
    end
  end
end
