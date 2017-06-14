require 'rails_helper'

RSpec.describe GpgSignature do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:gpg_key) }
  end

  describe 'validation' do
    subject { described_class.new }
    it { is_expected.to validate_presence_of(:commit_sha) }
    it { is_expected.to validate_presence_of(:project) }
  end
end
