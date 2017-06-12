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
    it 'email is verified if the user has the matching email' do
      user = create :user, email: 'bette.cartwright@example.com'
      gpg_key = create :gpg_key, key: GpgHelpers::User2.public_key, user: user

      expect(gpg_key.emails_with_verified_status).to match_array [
        ['bette.cartwright@example.com', true],
        ['bette.cartwright@example.net', false]
      ]
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
