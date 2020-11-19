# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TestCaseFailure do
  describe 'relationships' do
    it { is_expected.to belong_to(:build) }
    it { is_expected.to belong_to(:test_case) }
  end

  describe 'validations' do
    subject { build(:ci_test_case_failure) }

    it { is_expected.to validate_presence_of(:test_case) }
    it { is_expected.to validate_presence_of(:build) }
    it { is_expected.to validate_presence_of(:failed_at) }
  end

  describe '.recent_failures_count' do
    let_it_be(:project) { create(:project) }

    subject(:recent_failures) do
      described_class.recent_failures_count(
        project: project,
        test_case_keys: test_case_keys
      )
    end

    context 'when test case failures are within the date range and are for the test case keys' do
      let(:tc_1) { create(:ci_test_case, project: project) }
      let(:tc_2) { create(:ci_test_case, project: project) }
      let(:test_case_keys) { [tc_1.key_hash, tc_2.key_hash] }

      before do
        create_list(:ci_test_case_failure, 3, test_case: tc_1, failed_at: 1.day.ago)
        create_list(:ci_test_case_failure, 2, test_case: tc_2, failed_at: 3.days.ago)
      end

      it 'returns the number of failures for each test case key hash for the past 14 days by default' do
        expect(recent_failures).to eq(
          tc_1.key_hash => 3,
          tc_2.key_hash => 2
        )
      end
    end

    context 'when test case failures are within the date range but are not for the test case keys' do
      let(:tc) { create(:ci_test_case, project: project) }
      let(:test_case_keys) { ['some-other-key-hash'] }

      before do
        create(:ci_test_case_failure, test_case: tc, failed_at: 1.day.ago)
      end

      it 'excludes them from the count' do
        expect(recent_failures[tc.key_hash]).to be_nil
      end
    end

    context 'when test case failures are not within the date range but are for the test case keys' do
      let(:tc) { create(:ci_test_case, project: project) }
      let(:test_case_keys) { [tc.key_hash] }

      before do
        create(:ci_test_case_failure, test_case: tc, failed_at: 15.days.ago)
      end

      it 'excludes them from the count' do
        expect(recent_failures[tc.key_hash]).to be_nil
      end
    end
  end
end
