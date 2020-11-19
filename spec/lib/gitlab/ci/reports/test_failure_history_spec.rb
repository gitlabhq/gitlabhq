# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::TestFailureHistory, :aggregate_failures do
  include TestReportsHelper

  describe '#load!' do
    let_it_be(:project) { create(:project) }
    let(:failed_rspec) { create_test_case_rspec_failed }
    let(:failed_java) { create_test_case_java_failed }

    subject(:load_history) { described_class.new([failed_rspec, failed_java], project).load! }

    before do
      allow(Ci::TestCaseFailure)
        .to receive(:recent_failures_count)
        .with(project: project, test_case_keys: [failed_rspec.key, failed_java.key])
        .and_return(
          failed_rspec.key => 2,
          failed_java.key => 1
        )
    end

    it 'sets the recent failures for each matching failed test case in all test suites' do
      load_history

      expect(failed_rspec.recent_failures).to eq(count: 2, base_branch: 'master')
      expect(failed_java.recent_failures).to eq(count: 1, base_branch: 'master')
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(test_failure_history: false)
      end

      it 'does not set recent failures' do
        load_history

        expect(failed_rspec.recent_failures).to be_nil
        expect(failed_java.recent_failures).to be_nil
      end
    end
  end
end
