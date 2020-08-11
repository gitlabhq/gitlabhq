# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::TestSuiteSummary do
  let(:build_report_result_1) { build(:ci_build_report_result) }
  let(:build_report_result_2) { build(:ci_build_report_result, :with_junit_success) }
  let(:test_suite_summary) { described_class.new([build_report_result_1, build_report_result_2]) }

  describe '#name' do
    subject { test_suite_summary.name }

    context 'when test suite summary has several build report results' do
      it 'returns the suite name' do
        expect(subject).to eq("rspec")
      end
    end
  end

  describe '#build_ids' do
    subject { test_suite_summary.build_ids }

    context 'when test suite summary has several build report results' do
      it 'returns the build ids' do
        expect(subject).to contain_exactly(build_report_result_1.build_id, build_report_result_2.build_id)
      end
    end
  end

  describe '#total_time' do
    subject { test_suite_summary.total_time }

    context 'when test suite summary has several build report results' do
      it 'returns the total time' do
        expect(subject).to eq(0.84)
      end
    end
  end

  describe '#success_count' do
    subject { test_suite_summary.success_count }

    context 'when test suite summary has several build report results' do
      it 'returns the total success' do
        expect(subject).to eq(2)
      end
    end
  end

  describe '#failed_count' do
    subject { test_suite_summary.failed_count }

    context 'when test suite summary has several build report results' do
      it 'returns the total failed' do
        expect(subject).to eq(0)
      end
    end
  end

  describe '#error_count' do
    subject { test_suite_summary.error_count }

    context 'when test suite summary has several build report results' do
      it 'returns the total errored' do
        expect(subject).to eq(2)
      end
    end
  end

  describe '#skipped_count' do
    subject { test_suite_summary.skipped_count }

    context 'when test suite summary has several build report results' do
      it 'returns the total skipped' do
        expect(subject).to eq(0)
      end
    end
  end

  describe '#total_count' do
    subject { test_suite_summary.total_count }

    context 'when test suite summary has several build report results' do
      it 'returns the total count' do
        expect(subject).to eq(4)
      end
    end
  end

  describe '#to_h' do
    subject { test_suite_summary.to_h }

    context 'when test suite summary has several build report results' do
      it 'returns the total as a hash' do
        expect(subject).to include(:time, :count, :success, :failed, :skipped, :error)
      end
    end
  end
end
