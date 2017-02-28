require 'rails_helper'

describe GpgKey do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "validation" do
    it { is_expected.to validate_presence_of(:key) }
    it { is_expected.to validate_uniqueness_of(:key) }
    it { is_expected.to allow_value("-----BEGIN PGP PUBLIC KEY BLOCK-----\nkey").for(:key) }
    it { is_expected.not_to allow_value("-----BEGIN PGP PUBLIC KEY BLOCK-----\nkey\n-----BEGIN PGP PUBLIC KEY BLOCK-----").for(:key) }
    it { is_expected.not_to allow_value('BEGIN PGP').for(:key) }
  end

  context 'callbacks', :gpg do
    describe 'extract_fingerprint' do
      it 'extracts the fingerprint from the gpg key' do
        gpg_key = described_class.new(key: GpgHelpers::User1.public_key)
        gpg_key.valid?
        expect(gpg_key.fingerprint).to eq GpgHelpers::User1.fingerprint
      end
    end

    describe 'add_to_keychain' do
      context "user's email matches one of the key's emails" do
        it 'calls .add after create' do
          expect(Gitlab::Gpg::CurrentKeyChain).to receive(:add).with(GpgHelpers::User2.public_key)
          user = create :user, email: GpgHelpers::User2.emails.first
          create :gpg_key, user: user, key: GpgHelpers::User2.public_key
        end
      end

      context "user's email does not match one of the key's emails" do
        it 'does not call .add after create' do
          expect(Gitlab::Gpg::CurrentKeyChain).not_to receive(:add)
          user = create :user
          create :gpg_key, user: user, key: GpgHelpers::User2.public_key
        end
      end
    end

    describe 'remove_from_keychain' do
      it 'calls remove_from_keychain after destroy' do
        allow(Gitlab::Gpg::CurrentKeyChain).to receive :add
        gpg_key = create :gpg_key

        expect(
          Gitlab::Gpg::CurrentKeyChain
        ).to receive(:remove).with(GpgHelpers::User1.fingerprint)

        gpg_key.destroy!
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
  end

  describe '#emails', :gpg do
    it 'returns the emails from the gpg key' do
      gpg_key = create :gpg_key, key: GpgHelpers::User1.public_key

      expect(gpg_key.emails).to eq GpgHelpers::User1.emails
    end
  end

  describe '#emails_with_verified_status', :gpg do
    context 'key is in the keychain' do
      it 'email is verified if the user has the matching email' do
        user = create :user, email: 'bette.cartwright@example.com'
        gpg_key = create :gpg_key, key: GpgHelpers::User2.public_key, user: user

        expect(gpg_key.emails_with_verified_status).to match_array [
          ['bette.cartwright@example.com', true],
          ['bette.cartwright@example.net', false]
        ]
      end
    end

    context 'key is in not the keychain' do
      it 'emails are unverified' do
        user = create :user, email: 'bette.cartwright@example.com'
        gpg_key = create :gpg_key, key: GpgHelpers::User2.public_key, user: user

        Gitlab::Gpg::CurrentKeyChain.remove(GpgHelpers::User2.fingerprint)

        expect(gpg_key.emails_with_verified_status).to match_array [
          ['bette.cartwright@example.com', false],
          ['bette.cartwright@example.net', false]
        ]
      end
    end
  end

  describe 'notification' do
    include EmailHelpers

    let(:user) { create(:user) }

    it 'sends a notification' do
      perform_enqueued_jobs do
        create(:gpg_key, user: user)
      end

      should_email(user)
    end
  end
end
