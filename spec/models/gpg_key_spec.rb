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
      it 'calls add_to_keychain after create' do
        expect(Gitlab::Gpg).to receive(:add_to_keychain).with(GpgHelpers::User1.public_key)
        create :gpg_key
      end
    end

    describe 'remove_from_keychain' do
      it 'calls remove_from_keychain after destroy' do
        allow(Gitlab::Gpg).to receive :add_to_keychain
        gpg_key = create :gpg_key

        expect(Gitlab::Gpg).to receive(:remove_from_keychain).with(GpgHelpers::User1.fingerprint)

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

      expect(gpg_key.emails).to eq [GpgHelpers::User1.email]
    end
  end
end
