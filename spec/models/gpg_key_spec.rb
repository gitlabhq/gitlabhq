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

    describe 'synchronize_keychain' do
      it 'calls #synchronize_keychain after create' do
        gpg_key = build :gpg_key
        expect(gpg_key).to receive(:synchronize_keychain)
        gpg_key.save!
      end

      it 'calls #remove_from_keychain after destroy' do
        gpg_key = create :gpg_key
        expect(gpg_key).to receive(:synchronize_keychain)
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

  describe '#emails_in_keychain', :gpg do
    it 'returns the emails from the keychain' do
      user = create :user, email: GpgHelpers::User1.emails.first
      gpg_key = create :gpg_key, key: GpgHelpers::User1.public_key, user: user

      expect(gpg_key.emails_in_keychain).to eq GpgHelpers::User1.emails
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

  describe '#synchronize_keychain', :gpg do
    context "user's email matches one of the key's emails" do
      it 'adds the key to the keychain' do
        user = create :user, email: GpgHelpers::User1.emails.first
        gpg_key = create :gpg_key, user: user

        expect(gpg_key).to receive(:add_to_keychain)

        gpg_key.synchronize_keychain
      end
    end

    context "user's email does not match one of the key's emails" do
      it 'does not add the key to the keychain' do
        user = create :user, email: 'stepanie@cole.us'
        gpg_key = create :gpg_key, user: user

        expect(gpg_key).to receive(:remove_from_keychain)

        gpg_key.synchronize_keychain
      end
    end
  end

  describe '#add_to_keychain', :gpg do
    it 'calls .add_to_keychain' do
      expect(Gitlab::Gpg::CurrentKeyChain).to receive(:add).with(GpgHelpers::User2.public_key)
      gpg_key = create :gpg_key, key: GpgHelpers::User2.public_key
      gpg_key.send(:add_to_keychain)
    end
  end

  describe '#remove_from_keychain', :gpg do
    it 'calls .remove_from_keychain' do
      allow(Gitlab::Gpg::CurrentKeyChain).to receive(:remove).with(GpgHelpers::User2.fingerprint)
      gpg_key = create :gpg_key, key: GpgHelpers::User2.public_key
      gpg_key.send(:remove_from_keychain)
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
