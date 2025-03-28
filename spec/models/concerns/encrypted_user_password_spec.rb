# frozen_string_literal: true

require 'spec_helper'

RSpec.describe User, feature_category: :system_access do
  describe '#authenticatable_salt' do
    let(:user) { build(:user, encrypted_password: encrypted_password) }

    subject(:authenticatable_salt) { user.authenticatable_salt }

    context 'when password is stored in BCrypt format' do
      let(:encrypted_password) { '$2a$10$AvwDCyF/8HnlAv./UkAZx.vAlKRS89yNElP38FzdgOmVaSaiDL7xm' }

      it 'returns the first 30 characters of the encrypted_password' do
        expect(authenticatable_salt).to eq(user.encrypted_password[0, 29])
      end
    end

    context 'when password is stored in PBKDF2 format' do
      let(:encrypted_password) do
        '$pbkdf2-sha512$20000$rKbYsScsDdk$iwWBewXmrkD2fFfaG1SDcMIvl9gvEo3fBWUAfiqyVceTlw/DYgKBByHzf45pF5Qn59R4R.NQHs' \
          'FpvZB4qlsYmw'
      end

      it 'uses the decoded password salt' do
        expect(authenticatable_salt).to eq('aca6d8b1272c0dd9')
      end

      it 'does not use the first 30 characters of the encrypted_password' do
        expect(authenticatable_salt).not_to eq(encrypted_password[0, 29])
      end
    end

    context 'when the encrypted_password is an unknown type' do
      let(:encrypted_password) { '$argon2i$v=19$m=512,t=4,p=2$eM+ZMyYkpDRGaI3xXmuNcQ$c5DeJg3eb5dskVt1mDdxfw' }

      it 'returns the first 30 characters of the encrypted_password' do
        expect(authenticatable_salt).to eq(encrypted_password[0, 29])
      end
    end
  end

  describe '#valid_password?' do
    subject(:validate_password) { user.valid_password?(password) }

    let(:user) { build(:user, encrypted_password: encrypted_password) }
    let(:password) { described_class.random_password }

    shared_examples 'password validation fails when the password is encrypted using an unsupported method' do
      let(:encrypted_password) { '$argon2i$v=19$m=512,t=4,p=2$eM+ZMyYkpDRGaI3xXmuNcQ$c5DeJg3eb5dskVt1mDdxfw' }

      it { is_expected.to eq(false) }
    end

    context 'when the default encryption method is BCrypt' do
      context 'when the user password is hashed with work factor 4' do
        let(:encrypted_password) { "$2a$04$ThzqXSFnlW3uH86uQ79puOU7vARSFuuNzb1nUGfsBeYtCLkdymAQW" }
        let(:increase_password_storage_stretches) { nil }

        before do
          stub_feature_flags(increase_password_storage_stretches: increase_password_storage_stretches)
        end

        context 'when feature flag is set to true' do
          let(:increase_password_storage_stretches) { true }

          it 'upgrades stretches' do
            expect(user.encrypted_password).to start_with('$2a$04$')
            user.valid_password?('security')
            expect(user.encrypted_password).to start_with('$2a$05$')
          end
        end

        context 'when feature flag is set to false' do
          let(:increase_password_storage_stretches) { false }

          it 'does not upgrade stretches' do
            expect(user.encrypted_password).to start_with('$2a$04$')
            user.valid_password?('security')
            expect(user.encrypted_password).to start_with('$2a$04$')
          end
        end
      end

      it_behaves_like 'password validation fails when the password is encrypted using an unsupported method'

      context 'when the user password PBKDF2+SHA512' do
        let(:encrypted_password) do
          Devise::Pbkdf2Encryptable::Encryptors::Pbkdf2Sha512.digest(
            password, 20_000, Devise.friendly_token[0, 16])
        end

        it { is_expected.to eq(true) }

        it 're-encrypts the password as BCrypt' do
          expect(user.encrypted_password).to start_with('$pbkdf2-sha512$')

          validate_password

          expect(user.encrypted_password).to start_with('$2a$')
        end
      end

      context 'when in FIPS mode and salt length 16', :fips_mode do
        let(:encrypted_password) do
          Devise::Pbkdf2Encryptable::Encryptors::Pbkdf2Sha512.digest(
            password, 20_000, Devise.friendly_token[0, 16])
        end

        def pbkdf2_salt_length(password)
          Devise::Pbkdf2Encryptable::Encryptors::Pbkdf2Sha512.split_digest(password)[:salt].length
        end

        it 're-encrypts the password with a stronger salt' do
          expect(user.encrypted_password).to start_with('$pbkdf2-sha512$')
          expect(pbkdf2_salt_length(user.encrypted_password)).to eq(16)

          validate_password

          expect(user.encrypted_password).to start_with('$pbkdf2-sha512$')
          expect(pbkdf2_salt_length(user.encrypted_password)).to eq(64)
        end
      end
    end

    context 'when the default encryption method is PBKDF2+SHA512 and the user password is BCrypt', :fips_mode do
      it_behaves_like 'password validation fails when the password is encrypted using an unsupported method'

      context 'when the user password BCrypt' do
        let(:encrypted_password) { Devise::Encryptor.digest(described_class, password) }

        it { is_expected.to eq(true) }

        it 're-encrypts the password as PBKDF2+SHA512' do
          expect(user.encrypted_password).to start_with('$2a$')

          validate_password

          expect(user.reload.encrypted_password).to start_with('$pbkdf2-sha512$')
        end
      end
    end
  end

  describe '#password=' do
    let(:user) { build(:user) }
    let(:password) { described_class.random_password }

    def compare_bcrypt_password(user, password)
      Devise::Encryptor.compare(described_class, user.encrypted_password, password)
    end

    def compare_pbkdf2_password(user, password)
      Devise::Pbkdf2Encryptable::Encryptors::Pbkdf2Sha512.compare(user.encrypted_password, password)
    end

    context 'when FIPS mode is enabled', :fips_mode do
      it 'calls PBKDF2 digest and not the default Devise encryptor' do
        expect(Devise::Pbkdf2Encryptable::Encryptors::Pbkdf2Sha512)
          .to receive(:digest).at_least(:once).and_call_original
        expect(Devise::Encryptor).not_to receive(:digest)

        user.password = password
      end

      it 'saves the password in PBKDF2 format' do
        user.password = password
        user.save!

        expect(compare_pbkdf2_password(user, password)).to eq(true)
        expect { compare_bcrypt_password(user, password) }.to raise_error(::BCrypt::Errors::InvalidHash)
      end
    end

    it 'calls default Devise encryptor and not the PBKDF2 encryptor' do
      expect(Devise::Encryptor).to receive(:digest).at_least(:once).and_call_original
      expect(Devise::Pbkdf2Encryptable::Encryptors::Pbkdf2Sha512).not_to receive(:digest)

      user.password = password
    end

    it 'saves the password in BCrypt format' do
      user.password = password
      user.save!

      expect { compare_pbkdf2_password(user, password) }
        .to raise_error Devise::Pbkdf2Encryptable::Encryptors::InvalidHash
      expect(compare_bcrypt_password(user, password)).to eq(true)
    end
  end
end
