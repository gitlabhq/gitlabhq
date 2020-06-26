# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::TestReportSummary do
  let(:build_report_result_1) { build(:ci_build_report_result) }
  let(:build_report_result_2) { build(:ci_build_report_result, :with_junit_success) }
  let(:test_report_summary) { described_class.new([build_report_result_1, build_report_result_2]) }

  describe '#total' do
    subject { test_report_summary.total }

    context 'when test report summary has several build report results' do
      it 'returns test suite summary object' do
        expect(subject).to be_a_kind_of(Gitlab::Ci::Reports::TestSuiteSummary)
      end
    end
  end

  describe '#total_time' do
    subject { test_report_summary.total_time }

    context 'when test report summary has several build report results' do
      it 'returns the total' do
        expect(subject).to eq(0.84)
      end
    end
  end

  describe '#total_count' do
    subject { test_report_summary.total_count }

    context 'when test report summary has several build report results' do
      it 'returns the total count' do
        expect(subject).to eq(4)
      end
    end
  end

  describe '#success_count' do
    subject { test_report_summary.success_count }

    context 'when test suite summary has several build report results' do
      it 'returns the total success' do
        expect(subject).to eq(2)
      end
    end
  end

  describe '#failed_count' do
    subject { test_report_summary.failed_count }

    context 'when test suite summary has several build report results' do
      it 'returns the total failed' do
        expect(subject).to eq(0)
      end
    end
  end

  describe '#error_count' do
    subject { test_report_summary.error_count }

    context 'when test suite summary has several build report results' do
      it 'returns the total errored' do
        expect(subject).to eq(2)
      end
    end
  end

  describe '#skipped_count' do
    subject { test_report_summary.skipped_count }

    context 'when test suite summary has several build report results' do
      it 'returns the total skipped' do
        expect(subject).to eq(0)
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
