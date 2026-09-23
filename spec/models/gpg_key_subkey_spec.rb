# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GpgKeySubkey, feature_category: :source_code_management do
  subject { build(:gpg_key_subkey) }

  describe 'associations' do
    it { is_expected.to belong_to(:gpg_key) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:gpg_key_id) }
    it { is_expected.to validate_presence_of(:fingerprint) }
    it { is_expected.to validate_presence_of(:keyid) }
  end

  describe 'delegations' do
    it 'answers with the identities of its key, without the revoked uid', :aggregate_failures do
      user = create :user, email: GpgHelpers::UserWithRevokedUid.emails.first
      create :email, :confirmed, user: user, email: GpgHelpers::UserWithRevokedUid.revoked_emails.first
      user.reload
      gpg_key = create :gpg_key, key: GpgHelpers::UserWithRevokedUid.public_key, user: user
      subkey = gpg_key.subkeys.find_by(fingerprint: GpgHelpers::UserWithRevokedUid.subkey_fingerprints.first)

      expect(subkey.user_infos).to eq([{
        name: GpgHelpers::UserWithRevokedUid.names.first,
        email: GpgHelpers::UserWithRevokedUid.emails.first
      }])
      expect(subkey.verified?).to be_truthy
      expect(subkey.verified_and_belongs_to_email?(GpgHelpers::UserWithRevokedUid.emails.first)).to be_truthy
      expect(subkey.verified_and_belongs_to_email?(GpgHelpers::UserWithRevokedUid.revoked_emails.first))
        .to be_falsey
    end
  end
end
