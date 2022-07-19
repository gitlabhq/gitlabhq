# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::TestReport do
  include TestReportsHelper

  let(:test_reports) { described_class.new }

  describe '#get_suite' do
    subject { test_reports.get_suite(suite_name) }

    context 'when suite name is rspec' do
      let(:suite_name) { 'rspec' }

      it { expect(subject.name).to eq('rspec') }

      it 'initializes a new test suite and returns it' do
        expect(Gitlab::Ci::Reports::TestSuite).to receive(:new).and_call_original

        is_expected.to be_a(Gitlab::Ci::Reports::TestSuite)
      end

      context 'when suite name is already allocated' do
        before do
          subject
        end

        it 'does not initialize a new test suite' do
          expect(Gitlab::Ci::Reports::TestSuite).not_to receive(:new)

          is_expected.to be_a(Gitlab::Ci::Reports::TestSuite)
        end
      end
    end
  end

  describe '#total_time' do
    subject { test_reports.total_time }

    before do
      test_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
      test_reports.get_suite('junit').add_test_case(create_test_case_java_success)
    end

    it 'returns the total time' do
      is_expected.to eq(6.66)
    end
  end

  describe '#total_count' do
    subject { test_reports.total_count }

    before do
      test_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
      test_reports.get_suite('junit').add_test_case(create_test_case_java_success)
    end

    it 'returns the total count' do
      is_expected.to eq(2)
    end
  end

  describe '#total_status' do
    subject { test_reports.total_status }

    context 'when all test cases succeeded' do
      before do
        test_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
        test_reports.get_suite('junit').add_test_case(create_test_case_java_success)
      end

      it 'returns correct total status' do
        is_expected.to eq(Gitlab::Ci::Reports::TestCase::STATUS_SUCCESS)
      end
    end

    context 'when there is a failed test case' do
      before do
        test_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
        test_reports.get_suite('junit').add_test_case(create_test_case_java_failed)
      end

      it 'returns correct total status' do
        is_expected.to eq(Gitlab::Ci::Reports::TestCase::STATUS_FAILED)
      end
    end

    context 'when there is a skipped test case' do
      before do
        test_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
        test_reports.get_suite('junit').add_test_case(create_test_case_java_skipped)
      end

      it 'returns correct total status' do
        is_expected.to eq(Gitlab::Ci::Reports::TestCase::STATUS_SUCCESS)
      end
    end

    context 'when there is an error test case' do
      before do
        test_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
        test_reports.get_suite('junit').add_test_case(create_test_case_java_error)
      end

      it 'returns correct total status' do
        is_expected.to eq(Gitlab::Ci::Reports::TestCase::STATUS_FAILED)
      end
    end
  end

  describe '#with_attachment' do
    let(:test_case) { build(:report_test_case, :failed) }

    subject { test_reports.with_attachment! }

    context 'when test suites do not contain an attachment' do
      before do
        test_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
        test_reports.get_suite('junit').add_test_case(test_case)
      end

      it 'returns empty test suites' do
        expect(subject.test_suites).to be_empty
      end
    end

    context 'when test suites contain an attachment' do
      let(:test_case_succes) { build(:report_test_case) }
      let(:test_case_with_attachment) { build(:report_test_case, :failed_with_attachment) }

      before do
        test_reports.get_suite('rspec').add_test_case(test_case_succes)
        test_reports.get_suite('junit').add_test_case(test_case_with_attachment)
      end

      it 'returns test suites with attachment' do
        expect(subject.test_suites.count).to eq(1)
        expect(subject.test_suites['junit'].test_cases['failed']).to be_present
      end
    end
  end

  describe '#suite_errors' do
    subject { test_reports.suite_errors }

    context 'when a suite has normal spec errors or failures' do
      before do
        test_reports.get_suite('junit').add_test_case(create_test_case_java_success)
        test_reports.get_suite('junit').add_test_case(create_test_case_java_failed)
        test_reports.get_suite('junit').add_test_case(create_test_case_java_error)
      end

      it { is_expected.to be_empty }
    end

    context 'when there is an error test case' do
      before do
        test_reports.get_suite('rspec').add_test_case(create_test_case_rspec_success)
        test_reports.get_suite('junit').set_suite_error('Existential parsing error')
      end

      it { is_expected.to eq({ 'junit' => 'Existential parsing error' }) }
    end
  end

  Gitlab::Ci::Reports::TestCase::STATUS_TYPES.each do |status_type|
    describe "##{status_type}_count" do
      subject { test_reports.public_send("#{status_type}_count") }

      context "when #{status_type} test case exists" do
        before do
          test_reports.get_suite('rspec').add_test_case(public_send("create_test_case_rspec_#{status_type}"))
          test_reports.get_suite('junit').add_test_case(public_send("create_test_case_java_#{status_type}"))
        end

        it 'returns the count' do
          is_expected.to eq(2)
        end
      end

      context "when #{status_type} test case do not exist" do
        it 'returns nothing' do
          is_expected.to be(0)
        end
      end
    end
  end
end
