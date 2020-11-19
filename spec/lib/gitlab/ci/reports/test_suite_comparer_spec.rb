# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::TestSuiteComparer, :aggregate_failures do
  include TestReportsHelper

  let(:comparer) { described_class.new(name, base_suite, head_suite) }
  let(:name) { 'rspec' }
  let(:base_suite) { Gitlab::Ci::Reports::TestSuite.new(name) }
  let(:head_suite) { Gitlab::Ci::Reports::TestSuite.new(name) }
  let(:test_case_success) { create_test_case_java_success }
  let(:test_case_failed) { create_test_case_java_failed }
  let(:test_case_error) { create_test_case_java_error }

  describe '#new_failures' do
    subject { comparer.new_failures }

    context 'when head suite has a newly failed test case which does not exist in base' do
      before do
        base_suite.add_test_case(test_case_success)
        head_suite.add_test_case(test_case_failed)
      end

      it 'returns the failed test case' do
        is_expected.to eq([test_case_failed])
      end
    end

    context 'when head suite still has a failed test case which failed in base' do
      before do
        base_suite.add_test_case(test_case_failed)
        head_suite.add_test_case(test_case_failed)
      end

      it 'does not return the failed test case' do
        is_expected.to be_empty
      end
    end

    context 'when head suite has a success test case which failed in base' do
      before do
        base_suite.add_test_case(test_case_failed)
        head_suite.add_test_case(test_case_success)
      end

      it 'does not return the failed test case' do
        is_expected.to be_empty
      end
    end
  end

  describe '#existing_failures' do
    subject { comparer.existing_failures }

    context 'when head suite has a newly failed test case which does not exist in base' do
      before do
        base_suite.add_test_case(test_case_success)
        head_suite.add_test_case(test_case_failed)
      end

      it 'returns the failed test case' do
        is_expected.to be_empty
      end
    end

    context 'when head suite still has a failed test case which failed in base' do
      before do
        base_suite.add_test_case(test_case_failed)
        head_suite.add_test_case(test_case_failed)
      end

      it 'does not return the failed test case' do
        is_expected.to eq([test_case_failed])
      end
    end

    context 'when head suite has a success test case which failed in base' do
      before do
        base_suite.add_test_case(test_case_failed)
        head_suite.add_test_case(test_case_success)
      end

      it 'does not return the failed test case' do
        is_expected.to be_empty
      end
    end
  end

  describe '#resolved_failures' do
    subject { comparer.resolved_failures }

    context 'when head suite has a newly failed test case which does not exist in base' do
      before do
        base_suite.add_test_case(test_case_success)
        head_suite.add_test_case(test_case_failed)
      end

      it 'returns the failed test case' do
        is_expected.to be_empty
      end

      it 'returns the correct resolved count' do
        expect(comparer.resolved_count).to eq(0)
      end
    end

    context 'when head suite still has a failed test case which failed in base' do
      before do
        base_suite.add_test_case(test_case_failed)
        head_suite.add_test_case(test_case_failed)
      end

      it 'does not return the failed test case' do
        is_expected.to be_empty
      end

      it 'returns the correct resolved count' do
        expect(comparer.resolved_count).to eq(0)
      end
    end

    context 'when head suite has a success test case which failed in base' do
      before do
        base_suite.add_test_case(test_case_failed)
        head_suite.add_test_case(test_case_success)
      end

      it 'does not return the resolved test case' do
        is_expected.to eq([test_case_success])
      end

      it 'returns the correct resolved count' do
        expect(comparer.resolved_count).to eq(1)
      end
    end
  end

  describe '#new_errors' do
    subject { comparer.new_errors }

    context 'when head suite has a new error test case which does not exist in base' do
      before do
        base_suite.add_test_case(test_case_success)
        head_suite.add_test_case(test_case_error)
      end

      it 'returns the error test case' do
        is_expected.to eq([test_case_error])
      end
    end

    context 'when head suite still has an error test case which errored in base' do
      before do
        base_suite.add_test_case(test_case_error)
        head_suite.add_test_case(test_case_error)
      end

      it 'does not return the error test case' do
        is_expected.to be_empty
      end
    end

    context 'when head suite has a success test case which errored in base' do
      before do
        base_suite.add_test_case(test_case_error)
        head_suite.add_test_case(test_case_success)
      end

      it 'does not return the error test case' do
        is_expected.to be_empty
      end
    end
  end

  describe '#existing_errors' do
    subject { comparer.existing_errors }

    context 'when head suite has a new error test case which does not exist in base' do
      before do
        base_suite.add_test_case(test_case_success)
        head_suite.add_test_case(test_case_error)
      end

      it 'does not return the error test case' do
        is_expected.to be_empty
      end
    end

    context 'when head suite still has an error test case which errored in base' do
      before do
        base_suite.add_test_case(test_case_error)
        head_suite.add_test_case(test_case_error)
      end

      it 'returns the error test case' do
        is_expected.to eq([test_case_error])
      end
    end

    context 'when head suite has a success test case which errored in base' do
      before do
        base_suite.add_test_case(test_case_error)
        head_suite.add_test_case(test_case_success)
      end

      it 'does not return the error test case' do
        is_expected.to be_empty
      end
    end
  end

  describe '#resolved_errors' do
    subject { comparer.resolved_errors }

    context 'when head suite has a new error test case which does not exist in base' do
      before do
        base_suite.add_test_case(test_case_success)
        head_suite.add_test_case(test_case_error)
      end

      it 'does not return the error test case' do
        is_expected.to be_empty
      end

      it 'returns the correct resolved count' do
        expect(comparer.resolved_count).to eq(0)
      end
    end

    context 'when head suite still has an error test case which errored in base' do
      before do
        base_suite.add_test_case(test_case_error)
        head_suite.add_test_case(test_case_error)
      end

      it 'does not return the error test case' do
        is_expected.to be_empty
      end

      it 'returns the correct resolved count' do
        expect(comparer.resolved_count).to eq(0)
      end
    end

    context 'when head suite has a success test case which errored in base' do
      before do
        base_suite.add_test_case(test_case_error)
        head_suite.add_test_case(test_case_success)
      end

      it 'returns the resolved test case' do
        is_expected.to eq([test_case_success])
      end

      it 'returns the correct resolved count' do
        expect(comparer.resolved_count).to eq(1)
      end
    end
  end

  describe '#total_count' do
    subject { comparer.total_count }

    before do
      head_suite.add_test_case(test_case_success)
    end

    it 'returns the total test counts in head suite' do
      is_expected.to eq(1)
    end
  end

  describe '#failed_count' do
    subject { comparer.failed_count }

    context 'when there are a new failure and an existing failure' do
      let(:test_case_1_success) { create_test_case_rspec_success }
      let(:test_case_1_failed) { create_test_case_rspec_failed }
      let(:test_case_2_failed) { create_test_case_rspec_failed('case2') }

      before do
        base_suite.add_test_case(test_case_1_success)
        base_suite.add_test_case(test_case_2_failed)
        head_suite.add_test_case(test_case_1_failed)
        head_suite.add_test_case(test_case_2_failed)
      end

      it 'returns the correct count' do
        is_expected.to eq(2)
      end
    end

    context 'when there is a new failure' do
      before do
        base_suite.add_test_case(test_case_success)
        head_suite.add_test_case(test_case_failed)
      end

      it 'returns the correct count' do
        is_expected.to eq(1)
      end
    end

    context 'when there is an existing failure' do
      before do
        base_suite.add_test_case(test_case_failed)
        head_suite.add_test_case(test_case_failed)
      end

      it 'returns the correct count' do
        is_expected.to eq(1)
      end
    end
  end

  describe '#total_status' do
    subject { comparer.total_status }

    context 'when all test cases in head suite are success' do
      before do
        head_suite.add_test_case(test_case_success)
      end

      it 'returns the total status in head suite' do
        is_expected.to eq(Gitlab::Ci::Reports::TestCase::STATUS_SUCCESS)
      end
    end

    context 'when there is a failed test case in head suite' do
      before do
        head_suite.add_test_case(test_case_failed)
      end

      it 'returns the total status in head suite as failed' do
        is_expected.to eq(Gitlab::Ci::Reports::TestCase::STATUS_FAILED)
      end
    end

    context 'when there is an error test case in head suite' do
      before do
        head_suite.add_test_case(test_case_error)
      end

      it 'returns the total status in head suite as failed' do
        is_expected.to eq(Gitlab::Ci::Reports::TestCase::STATUS_FAILED)
      end
    end
  end

  describe '#limited_tests' do
    subject(:limited_tests) { comparer.limited_tests }

    context 'limits amount of tests returned' do
      before do
        stub_const("#{described_class}::DEFAULT_MAX_TESTS", 2)
        stub_const("#{described_class}::DEFAULT_MIN_TESTS", 1)
      end

      context 'prefers new over existing and resolved' do
        before do
          3.times { add_new_failure }
          3.times { add_new_error }
          3.times { add_existing_failure }
          3.times { add_existing_error }
          3.times { add_resolved_failure }
          3.times { add_resolved_error }
        end

        it 'returns 2 of each new category, and 1 of each resolved and existing' do
          expect(limited_tests.new_failures.count).to eq(2)
          expect(limited_tests.new_errors.count).to eq(2)
          expect(limited_tests.existing_failures.count).to eq(1)
          expect(limited_tests.existing_errors.count).to eq(1)
          expect(limited_tests.resolved_failures.count).to eq(1)
          expect(limited_tests.resolved_errors.count).to eq(1)
        end

        it 'does not affect the overall count' do
          expect(summary).to include(total: 18, resolved: 6, failed: 6, errored: 6)
        end
      end

      context 'prefers existing over resolved' do
        before do
          3.times { add_existing_failure }
          3.times { add_existing_error }
          3.times { add_resolved_failure }
          3.times { add_resolved_error }
        end

        it 'returns 2 of each existing category, and 1 of each resolved' do
          expect(limited_tests.new_failures.count).to eq(0)
          expect(limited_tests.new_errors.count).to eq(0)
          expect(limited_tests.existing_failures.count).to eq(2)
          expect(limited_tests.existing_errors.count).to eq(2)
          expect(limited_tests.resolved_failures.count).to eq(1)
          expect(limited_tests.resolved_errors.count).to eq(1)
        end

        it 'does not affect the overall count' do
          expect(summary).to include(total: 12, resolved: 6, failed: 3, errored: 3)
        end
      end

      context 'limits amount of resolved' do
        before do
          3.times { add_resolved_failure }
          3.times { add_resolved_error }
        end

        it 'returns 2 of each resolved category' do
          expect(limited_tests.new_failures.count).to eq(0)
          expect(limited_tests.new_errors.count).to eq(0)
          expect(limited_tests.existing_failures.count).to eq(0)
          expect(limited_tests.existing_errors.count).to eq(0)
          expect(limited_tests.resolved_failures.count).to eq(2)
          expect(limited_tests.resolved_errors.count).to eq(2)
        end

        it 'does not affect the overall count' do
          expect(summary).to include(total: 6, resolved: 6, failed: 0, errored: 0)
        end
      end
    end

    def summary
      {
        total: comparer.total_count,
        resolved: comparer.resolved_count,
        failed: comparer.failed_count,
        errored: comparer.error_count
      }
    end

    def add_new_failure
      failed_case = create_test_case_rspec_failed(SecureRandom.hex)
      head_suite.add_test_case(failed_case)
    end

    def add_new_error
      error_case = create_test_case_rspec_error(SecureRandom.hex)
      head_suite.add_test_case(error_case)
    end

    def add_existing_failure
      failed_case = create_test_case_rspec_failed(SecureRandom.hex)
      base_suite.add_test_case(failed_case)
      head_suite.add_test_case(failed_case)
    end

    def add_existing_error
      error_case = create_test_case_rspec_error(SecureRandom.hex)
      base_suite.add_test_case(error_case)
      head_suite.add_test_case(error_case)
    end

    def add_resolved_failure
      case_name = SecureRandom.hex
      failed_case = create_test_case_java_failed(case_name)
      success_case = create_test_case_java_success(case_name)
      base_suite.add_test_case(failed_case)
      head_suite.add_test_case(success_case)
    end

    def add_resolved_error
      case_name = SecureRandom.hex
      error_case = create_test_case_java_error(case_name)
      success_case = create_test_case_java_success(case_name)
      base_suite.add_test_case(error_case)
      head_suite.add_test_case(success_case)
    end
  end
end
