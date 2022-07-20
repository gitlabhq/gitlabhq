# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::TestReportsComparer do
  include TestReportsHelper

  let(:comparer) { described_class.new(base_reports, head_reports) }
  let(:base_reports) { Gitlab::Ci::Reports::TestReport.new }
  let(:head_reports) { Gitlab::Ci::Reports::TestReport.new }

  describe '#suite_comparers' do
    subject { comparer.suite_comparers }

    context 'when head and base reports include two test suites' do
      before do
        base_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
        base_reports.get_suite('junit').add_test_case(create_test_case_java_success)
        head_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
        head_reports.get_suite('junit').add_test_case(create_test_case_java_success)
      end

      it 'returns test suite comparers with specified values' do
        expect(subject[0]).to be_a(Gitlab::Ci::Reports::TestSuiteComparer)
        expect(subject[0].name).to eq('rspec')
        expect(subject[0].head_suite).to eq(head_reports.get_suite('rspec'))
        expect(subject[0].base_suite).to eq(base_reports.get_suite('rspec'))
        expect(subject[1]).to be_a(Gitlab::Ci::Reports::TestSuiteComparer)
        expect(subject[1].name).to eq('junit')
        expect(subject[1].head_suite).to eq(head_reports.get_suite('junit'))
        expect(subject[1].base_suite).to eq(base_reports.get_suite('junit'))
      end
    end
  end

  describe '#total_status' do
    subject { comparer.total_status }

    context 'when all tests cases are success in head suites' do
      before do
        head_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
        head_reports.get_suite('junit').add_test_case(create_test_case_java_success)
      end

      it 'returns the total status' do
        is_expected.to eq(Gitlab::Ci::Reports::TestCase::STATUS_SUCCESS)
      end
    end

    context 'when there is a failed test case in head suites' do
      before do
        head_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
        head_reports.get_suite('junit').add_test_case(create_test_case_java_failed)
      end

      it 'returns the total status in head suite' do
        is_expected.to eq(Gitlab::Ci::Reports::TestCase::STATUS_FAILED)
      end
    end

    context 'when there is an error test case in head suites' do
      before do
        head_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
        head_reports.get_suite('junit').add_test_case(create_test_case_java_error)
      end

      it 'returns the total status in head suite' do
        is_expected.to eq(Gitlab::Ci::Reports::TestCase::STATUS_FAILED)
      end
    end
  end

  describe '#total_count' do
    subject { comparer.total_count }

    before do
      head_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
      head_reports.get_suite('junit').add_test_case(create_test_case_java_failed)
    end

    it 'returns the total test counts in head suites' do
      is_expected.to eq(2)
    end
  end

  describe '#resolved_count' do
    subject { comparer.resolved_count }

    context 'when there is a resolved failure test case in head suites' do
      before do
        base_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
        base_reports.get_suite('junit').add_test_case(create_test_case_java_failed)
        head_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
        head_reports.get_suite('junit').add_test_case(create_test_case_java_success)
      end

      it 'returns the correct count' do
        is_expected.to eq(1)
      end
    end

    context 'when there is a resolved error test case in head suites' do
      before do
        base_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
        base_reports.get_suite('junit').add_test_case(create_test_case_java_error)
        head_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
        head_reports.get_suite('junit').add_test_case(create_test_case_java_success)
      end

      it 'returns the correct count' do
        is_expected.to eq(1)
      end
    end

    context 'when there are no resolved test cases in head suites' do
      before do
        base_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
        base_reports.get_suite('junit').add_test_case(create_test_case_java_failed)
        head_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
        head_reports.get_suite('junit').add_test_case(create_test_case_java_failed)
      end

      it 'returns the correct count' do
        is_expected.to eq(0)
      end
    end
  end

  describe '#failed_count' do
    subject { comparer.failed_count }

    context 'when there is a failed test case in head suites' do
      before do
        head_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
        head_reports.get_suite('junit').add_test_case(create_test_case_java_failed)
      end

      it 'returns the correct count' do
        is_expected.to eq(1)
      end
    end

    context 'when there are no failed test cases in head suites' do
      before do
        head_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
        head_reports.get_suite('junit').add_test_case(create_test_case_rspec_success)
      end

      it 'returns the correct count' do
        is_expected.to eq(0)
      end
    end
  end

  describe '#error_count' do
    subject { comparer.error_count }

    context 'when there is an error test case in head suites' do
      before do
        head_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
        head_reports.get_suite('junit').add_test_case(create_test_case_java_error)
      end

      it 'returns the correct count' do
        is_expected.to eq(1)
      end
    end

    context 'when there are no error test cases in head suites' do
      before do
        head_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
        head_reports.get_suite('junit').add_test_case(create_test_case_rspec_success)
      end

      it 'returns the correct count' do
        is_expected.to eq(0)
      end
    end
  end
end
