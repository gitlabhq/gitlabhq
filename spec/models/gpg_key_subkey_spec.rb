# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GpgKeySubkey do
  subject { build(:gpg_key_subkey) }

  describe 'associations' do
    it { is_expected.to belong_to(:gpg_key) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:gpg_key_id) }
    it { is_expected.to validate_presence_of(:fingerprint) }
    it { is_expected.to validate_presence_of(:keyid) }
  end

  it_behaves_like 'cells claimable model',
    subject_type: Cells::Claimable::CLAIMS_SUBJECT_TYPE::GPG_KEY,
    subject_key: :gpg_key_id,
    source_type: Cells::Claimable::CLAIMS_SOURCE_TYPE::RAILS_TABLE_GPG_KEY_SUBKEYS,
    claiming_attributes: [:fingerprint, :keyid]
end
