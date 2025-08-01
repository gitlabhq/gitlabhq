# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OauthAccessToken, feature_category: :system_access do
  let_it_be(:app_one) { create(:oauth_application) }
  let_it_be(:app_two) { create(:oauth_application) }
  let_it_be(:app_three) { create(:oauth_application) }
  let_it_be(:organization) { create(:organization) }

  let(:token) { create(:oauth_access_token, application_id: app_one.id) }

  describe 'scopes' do
    describe '.latest_per_application' do
      let!(:app_two_token1) { create(:oauth_access_token, application: app_two) }
      let!(:app_two_token2) { create(:oauth_access_token, application: app_two) }
      let!(:app_three_token1) { create(:oauth_access_token, application: app_three) }
      let!(:app_three_token2) { create(:oauth_access_token, application: app_three) }

      it 'returns only the latest token for each application' do
        expect(described_class.latest_per_application.map(&:id))
          .to match_array([app_two_token2.id, app_three_token2.id])
      end
    end
  end

  describe 'Doorkeeper secret storing' do
    it 'does not have a prefix' do
      expect(token.plaintext_token).not_to start_with('gl')
    end

    it 'stores the token in hashed format' do
      expect(token.token).not_to eq(token.plaintext_token)
    end

    it 'does not allow falling back to plaintext token comparison' do
      expect(described_class.by_token(token.token)).to be_nil
    end

    it 'finds a token by plaintext token' do
      expect(described_class.by_token(token.plaintext_token)).to be_a(described_class)
    end

    context 'when the token is stored in plaintext' do
      let(:plaintext_token) { Devise.friendly_token(20) }

      before do
        token.update_column(:token, plaintext_token)
      end

      it 'falls back to plaintext token comparison' do
        expect(described_class.by_token(plaintext_token)).to be_a(described_class)
      end
    end
  end

  describe '.find_by_fallback_token' do
    let(:plain_secret) { 'CzOBzBfU9F-HvsqfTaTXF4ivuuxYZuv3BoAK4pnvmyw' }
    let(:pbkdf2_token) { '$pbkdf2-sha512$20000$$.c0G5XJV...' }
    let(:sha512_token) { 'a' * 128 }
    let(:attr) { :token }

    context 'when token is already hashed' do
      it 'returns nil for PBKDF2 formatted tokens' do
        expect(described_class.find_by_fallback_token(attr, pbkdf2_token)).to be_nil
      end

      it 'returns nil for SHA512 formatted tokens (128 hex chars)' do
        expect(described_class.find_by_fallback_token(attr, sha512_token)).to be_nil
      end
    end

    context 'with actual fallback strategies' do
      let!(:pbkdf2_token) { create(:oauth_access_token, application: app_one) }
      let!(:sha512_token) { create(:oauth_access_token, application: app_two) }
      let!(:plain_token) { create(:oauth_access_token, application: app_three) }

      before do
        allow(described_class).to receive(:upgrade_fallback_value).and_call_original
      end

      it 'finds token stored with PBKDF2 strategy' do
        pbkdf2_hash = Gitlab::DoorkeeperSecretStoring::Token::Pbkdf2Sha512.transform_secret(plain_secret)
        pbkdf2_token.update_column(:token, pbkdf2_hash)

        result = described_class.find_by_fallback_token(:token, plain_secret)

        expect(result).to eq(pbkdf2_token)
        expect(described_class).to have_received(:upgrade_fallback_value).with(pbkdf2_token, :token,
          plain_secret)
      end

      it 'finds token stored with Plain strategy when PBKDF2 fails' do
        # Create a different plain secret that won't match any PBKDF2 token
        different_secret = 'different_plain_token_xyz'
        plain_token.update_column(:token, different_secret)

        result = described_class.find_by_fallback_token(:token, different_secret)

        expect(result).to eq(plain_token)
        expect(described_class).to have_received(:upgrade_fallback_value).with(plain_token, :token,
          different_secret)
      end

      it 'finds token stored with SHA512 strategy when PBKDF2 fails' do
        plaintext_token_value = "123456"
        value = Gitlab::DoorkeeperSecretStoring::Token::Sha512Hash.transform_secret(plaintext_token_value)
        sha512_token.update_column(:token, value)

        result = described_class.find_by_fallback_token(:token, plaintext_token_value)

        expect(result).to eq(sha512_token)
        expect(described_class).to have_received(:upgrade_fallback_value).with(sha512_token, :token,
          plaintext_token_value)
      end

      it 'upgrade legacy plain text tokens' do
        described_class.find_by_fallback_token(:token, plain_token.plaintext_token)
        pbkdf2_hash = Gitlab::DoorkeeperSecretStoring::Token::Pbkdf2Sha512.transform_secret(plain_token.plaintext_token)
        expect(plain_token.reload.token).to eq(pbkdf2_hash)
      end

      it 'returns nil when no strategy finds a match' do
        non_existent_secret = 'this_token_does_not_exist_anywhere'

        result = described_class.find_by_fallback_token(:token, non_existent_secret)

        expect(result).to be_nil
        expect(described_class).not_to have_received(:upgrade_fallback_value)
      end
    end
  end

  describe '.matching_token_for' do
    it 'does not find existing tokens' do
      expect(described_class.matching_token_for(app_one, token.resource_owner, token.scopes)).to be_nil
    end
  end

  describe '#expires_in' do
    context 'when token has expires_in value set' do
      it 'uses the expires_in value' do
        token = described_class.new(organization: organization, expires_in: 1.minute)

        expect(token).to be_valid
      end
    end

    context 'when token has nil expires_in' do
      it 'uses default value' do
        token = described_class.new(organization: organization, expires_in: nil)

        expect(token).to be_invalid
      end
    end
  end

  describe '#scope_user' do
    let_it_be(:user) { create(:user) }

    context 'when scopes match expected format' do
      where(:scopes) do
        [
          "user:%{user_id}",
          "other:scope user:%{user_id}",
          "user:%{user_id} other:scope",
          "api user:%{user_id} read_api"
        ]
      end

      with_them do
        let(:formatted_scopes) do
          format(scopes, user_id: user.id)
        end

        let(:oauth_access_token) { create(:oauth_access_token, scopes: formatted_scopes) }

        it 'returns the user' do
          expect(oauth_access_token.scope_user).to eq user
        end
      end
    end

    context 'when scopes do not match composite scope format' do
      where(:scopes) do
        [
          "user:#{non_existing_record_id}",
          'fuser:%{user_id}',
          'user:%{user_id}f',
          'user:%{user_id} user:2',
          'user:not_a_number',
          'some:other:scope',
          nil,
          ""
        ]
      end
      let(:formatted_scopes) do
        if scopes.presence
          format(scopes, user_id: user.id)
        else
          scopes
        end
      end

      let(:oauth_access_token) { create(:oauth_access_token, scopes: formatted_scopes) }

      with_them do
        it 'returns false' do
          expect(oauth_access_token.scope_user).to be_nil
        end
      end
    end
  end
end
