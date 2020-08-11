# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::TestReportSummary do
  let(:build_report_result_1) { build(:ci_build_report_result) }
  let(:build_report_result_2) { build(:ci_build_report_result, :with_junit_success) }
  let(:test_report_summary) { described_class.new([build_report_result_1, build_report_result_2]) }

  describe '#total' do
    subject { test_report_summary.total }

    context 'when test report summary has several build report results' do
      it 'returns all the total count in a hash' do
        expect(subject).to include(:time, :count, :success, :failed, :skipped, :error)
      end
    end
  end

  describe '#test_suites' do
    subject { test_report_summary.test_suites }

    context 'when test report summary has several build report results' do
      it 'returns test suites grouped by name' do
        expect(subject.keys).to eq(["rspec"])
        expect(subject.keys.size).to eq(1)
      end
    end
  end
end
