# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TestCase do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:test_case_failures) }
  end

  describe 'validations' do
    subject { build(:ci_test_case) }

    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:key_hash) }
  end

  describe '.find_or_create_by_batch' do
    it 'finds or creates records for the given test case keys', :aggregate_failures do
      project = create(:project)
      existing_tc = create(:ci_test_case, project: project)
      new_key = Digest::SHA256.hexdigest(SecureRandom.hex)
      keys = [existing_tc.key_hash, new_key]

      result = described_class.find_or_create_by_batch(project, keys)

      expect(result.map(&:key_hash)).to match_array([existing_tc.key_hash, new_key])
      expect(result).to all(be_persisted)
    end
  end
end
