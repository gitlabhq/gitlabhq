# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GpgKey do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:subkeys) }
  end

  describe "validation" do
    it { is_expected.to validate_presence_of(:user) }

    it { is_expected.to validate_presence_of(:key) }
    it { is_expected.to validate_uniqueness_of(:key) }

    it { is_expected.to allow_value("-----BEGIN PGP PUBLIC KEY BLOCK-----\nkey\n-----END PGP PUBLIC KEY BLOCK-----").for(:key) }

    it { is_expected.not_to allow_value("-----BEGIN PGP PUBLIC KEY BLOCK-----\nkey").for(:key) }
    it { is_expected.not_to allow_value("-----BEGIN PGP PUBLIC KEY BLOCK-----\nkey\n-----BEGIN PGP PUBLIC KEY BLOCK-----").for(:key) }
    it { is_expected.not_to allow_value("-----BEGIN PGP PUBLIC KEY BLOCK----------END PGP PUBLIC KEY BLOCK-----").for(:key) }
    it { is_expected.not_to allow_value("-----BEGIN PGP PUBLIC KEY BLOCK-----").for(:key) }
    it { is_expected.not_to allow_value("-----END PGP PUBLIC KEY BLOCK-----").for(:key) }
    it { is_expected.not_to allow_value("key\n-----END PGP PUBLIC KEY BLOCK-----").for(:key) }
    it { is_expected.not_to allow_value('BEGIN PGP').for(:key) }
  end

  context 'callbacks' do
    describe 'extract_fingerprint' do
      it 'extracts the fingerprint from the gpg key' do
        gpg_key = described_class.new(key: GpgHelpers::User1.public_key)
        gpg_key.valid?
        expect(gpg_key.fingerprint).to eq GpgHelpers::User1.fingerprint
      end
    end

    describe 'extract_primary_keyid' do
      it 'extracts the primary keyid from the gpg key' do
        gpg_key = described_class.new(key: GpgHelpers::User1.public_key)
        gpg_key.valid?
        expect(gpg_key.primary_keyid).to eq GpgHelpers::User1.primary_keyid
      end
    end

    describe 'generate_subkeys' do
      it 'extracts the subkeys from the gpg key' do
        gpg_key = create(:gpg_key, key: GpgHelpers::User1.public_key_with_extra_signing_key)

        expect(gpg_key.subkeys.count).to eq(2)
      end
    end
  end

  describe '#key=' do
    it 'strips white spaces' do
      key = <<~KEY.strip
        -----BEGIN PGP PUBLIC KEY BLOCK-----
        Version: GnuPG v1

        mQENBFMOSOgBCADFCYxmnXFbrDhfvlf03Q/bQuT+nZu46BFGbo7XkUjDowFXJQhP
        -----END PGP PUBLIC KEY BLOCK-----
      KEY

      expect(described_class.new(key: " #{key} ").key).to eq(key)
    end

    it 'does not strip when the key is nil' do
      expect(described_class.new(key: nil).key).to be_nil
    end
  end

  describe '#user_infos' do
    it 'returns the user infos from the gpg key' do
      gpg_key = create :gpg_key, key: GpgHelpers::User1.public_key
      expect(Gitlab::Gpg).to receive(:user_infos_from_key).with(gpg_key.key)

      gpg_key.user_infos
    end
  end

  describe '#verified_user_infos' do
    it 'returns the user infos if it is verified' do
      user = create :user, email: GpgHelpers::User1.emails.first
      gpg_key = create :gpg_key, key: GpgHelpers::User1.public_key, user: user

      expect(gpg_key.verified_user_infos).to eq([{
        name: GpgHelpers::User1.names.first,
        email: GpgHelpers::User1.emails.first
      }])
    end

    it 'returns an empty array if the user info is not verified' do
      user = create :user, email: 'unrelated@example.com'
      gpg_key = create :gpg_key, key: GpgHelpers::User1.public_key, user: user

      expect(gpg_key.verified_user_infos).to eq([])
    end
  end

  describe '#emails_with_verified_status' do
    it 'email is verified if the user has the matching email' do
      user = create :user, email: 'bette.cartwright@example.com'
      gpg_key = create :gpg_key, key: GpgHelpers::User2.public_key, user: user
      create :email, user: user
      user.reload

      expect(gpg_key.emails_with_verified_status).to eq(
        'bette.cartwright@example.com' => true,
        'bette.cartwright@example.net' => false
      )

      create :email, :confirmed, user: user, email: 'bette.cartwright@example.net'
      user.reload
      expect(gpg_key.emails_with_verified_status).to eq(
        'bette.cartwright@example.com' => true,
        'bette.cartwright@example.net' => true
      )
    end
  end

  describe '#verified?' do
    it 'returns true if one of the email addresses in the key belongs to the user' do
      user = create :user, email: 'bette.cartwright@example.com'
      gpg_key = create :gpg_key, key: GpgHelpers::User2.public_key, user: user

      expect(gpg_key.verified?).to be_truthy
    end

    it 'returns false if none of the email addresses in the key does not belong to the user' do
      user = create :user, email: 'someone.else@example.com'
      gpg_key = create :gpg_key, key: GpgHelpers::User2.public_key, user: user

      expect(gpg_key.verified?).to be_falsey
    end
  end

  describe 'verified_and_belongs_to_email?' do
    it 'returns false if none of the email addresses in the key does not belong to the user' do
      user = create :user, email: 'someone.else@example.com'
      gpg_key = create :gpg_key, key: GpgHelpers::User2.public_key, user: user

      expect(gpg_key.verified?).to be_falsey
      expect(gpg_key.verified_and_belongs_to_email?('someone.else@example.com')).to be_falsey
    end

    it 'returns false if one of the email addresses in the key belongs to the user and does not match the provided email' do
      user = create :user, email: 'bette.cartwright@example.com'
      gpg_key = create :gpg_key, key: GpgHelpers::User2.public_key, user: user

      expect(gpg_key.verified?).to be_truthy
      expect(gpg_key.verified_and_belongs_to_email?('bette.cartwright@example.net')).to be_falsey
    end

    it 'returns true if one of the email addresses in the key belongs to the user and matches the provided email' do
      user = create :user, email: 'bette.cartwright@example.com'
      gpg_key = create :gpg_key, key: GpgHelpers::User2.public_key, user: user

      expect(gpg_key.verified?).to be_truthy
      expect(gpg_key.verified_and_belongs_to_email?('bette.cartwright@example.com')).to be_truthy
    end

    it 'returns true if one of the email addresses in the key belongs to the user and case-insensitively matches the provided email' do
      user = create :user, email: 'bette.cartwright@example.com'
      gpg_key = create :gpg_key, key: GpgHelpers::User2.public_key, user: user

      expect(gpg_key.verified?).to be_truthy
      expect(gpg_key.verified_and_belongs_to_email?('Bette.Cartwright@example.com')).to be_truthy
    end
  end

  describe '#revoke' do
    it 'invalidates all associated gpg signatures and destroys the key' do
      gpg_key = create :gpg_key
      gpg_signature = create :gpg_signature, verification_status: :verified, gpg_key: gpg_key

      unrelated_gpg_key = create :gpg_key, key: GpgHelpers::User2.public_key
      unrelated_gpg_signature = create :gpg_signature, verification_status: :verified, gpg_key: unrelated_gpg_key

      gpg_key.revoke

      expect(gpg_signature.reload).to have_attributes(
        verification_status: 'unknown_key',
        gpg_key: nil
      )

      expect(gpg_key.destroyed?).to be true

      # unrelated signature is left untouched
      expect(unrelated_gpg_signature.reload).to have_attributes(
        verification_status: 'verified',
        gpg_key: unrelated_gpg_key
      )

      expect(unrelated_gpg_key.destroyed?).to be false
    end

    it 'deletes all the associated subkeys' do
      gpg_key = create :gpg_key, key: GpgHelpers::User3.public_key

      expect(gpg_key.subkeys).to be_present

      gpg_key.revoke

      expect(gpg_key.subkeys.reload).to be_blank
    end

    it 'invalidates all signatures associated to the subkeys' do
      gpg_key = create :gpg_key, key: GpgHelpers::User3.public_key
      gpg_key_subkey = gpg_key.subkeys.last
      gpg_signature = create :gpg_signature, verification_status: :verified, gpg_key: gpg_key_subkey

      gpg_key.revoke

      expect(gpg_signature.reload).to have_attributes(
        verification_status: 'unknown_key',
        gpg_key: nil,
        gpg_key_subkey: nil
      )
    end
  end
end
