require 'rails_helper'

describe GpgKeySubkey do
  subject { build(:gpg_key_subkey) }

  describe 'associations' do
    it { is_expected.to belong_to(:gpg_key) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:gpg_key_id) }
    it { is_expected.to validate_presence_of(:fingerprint) }
    it { is_expected.to validate_presence_of(:keyid) }
  end
end
