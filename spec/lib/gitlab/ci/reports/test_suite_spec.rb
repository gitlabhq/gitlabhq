# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::TestSuite do
  include TestReportsHelper

  let(:test_suite) { described_class.new('Rspec') }
  let(:test_case_success) { create_test_case_rspec_success }
  let(:test_case_failed) { create_test_case_rspec_failed }
  let(:test_case_skipped) { create_test_case_rspec_skipped }
  let(:test_case_error) { create_test_case_rspec_error }

  it { expect(test_suite.name).to eq('Rspec') }

  describe '#add_test_case' do
    context 'when status of the test case is success' do
      it 'stores data correctly' do
        test_suite.add_test_case(test_case_success)

        expect(test_suite.test_cases[test_case_success.status][test_case_success.key])
          .to eq(test_case_success)
        expect(test_suite.total_time).to eq(1.11)
      end
    end

    context 'when status of the test case is failed' do
      it 'stores data correctly' do
        test_suite.add_test_case(test_case_failed)

        expect(test_suite.test_cases[test_case_failed.status][test_case_failed.key])
          .to eq(test_case_failed)
        expect(test_suite.total_time).to eq(2.22)
      end
    end

    context 'when two test cases are added' do
      it 'sums up total time' do
        test_suite.add_test_case(test_case_success)
        test_suite.add_test_case(test_case_failed)

        expect(test_suite.total_time).to eq(3.33)
      end
    end
  end

  describe '#total_count' do
    subject { test_suite.total_count }

    before do
      test_suite.add_test_case(test_case_success)
      test_suite.add_test_case(test_case_failed)
      test_suite.add_test_case(test_case_skipped)
      test_suite.add_test_case(test_case_error)
    end

    it { is_expected.to eq(4) }
  end

  describe '#total_status' do
    subject { test_suite.total_status }

    context 'when all test cases succeeded' do
      before do
        test_suite.add_test_case(test_case_success)
      end

      it { is_expected.to eq(Gitlab::Ci::Reports::TestCase::STATUS_SUCCESS) }
    end

    context 'when a test case failed' do
      before do
        test_suite.add_test_case(test_case_success)
        test_suite.add_test_case(test_case_failed)
      end

      it { is_expected.to eq(Gitlab::Ci::Reports::TestCase::STATUS_FAILED) }
    end

    context 'when a test case errored' do
      before do
        test_suite.add_test_case(test_case_success)
        test_suite.add_test_case(test_case_error)
      end

      it { is_expected.to eq(Gitlab::Ci::Reports::TestCase::STATUS_FAILED) }
    end
  end

  describe '#with_attachment' do
    subject { test_suite.with_attachment! }

    context 'when test cases do not contain an attachment' do
      let(:test_case) { build(:report_test_case, :failed) }

      before do
        test_suite.add_test_case(test_case)
      end

      it 'returns an empty hash' do
        expect(subject).to be_empty
      end
    end

    context 'when test cases contain an attachment' do
      let(:test_case_with_attachment) { build(:report_test_case, :failed_with_attachment) }

      before do
        test_suite.add_test_case(test_case_with_attachment)
      end

      it 'returns failed test cases with attachment' do
        expect(subject.count).to eq(1)
        expect(subject['failed']).to be_present
      end
    end
  end

  describe '#set_suite_error' do
    let(:set_suite_error) { test_suite.set_suite_error('message') }

    context 'when @suite_error is nil' do
      it 'returns message' do
        expect(set_suite_error).to eq('message')
      end

      it 'sets the new message' do
        set_suite_error
        expect(test_suite.suite_error).to eq('message')
      end
    end

    context 'when a suite_error has already been set' do
      before do
        test_suite.set_suite_error('old message')
      end

      it 'overwrites the existing message' do
        expect { set_suite_error }.to change(test_suite, :suite_error).from('old message').to('message')
      end
    end
  end

  describe '#+' do
    let(:test_suite_2) { described_class.new('Rspec') }

    subject { test_suite + test_suite_2 }

    context 'when adding multiple suites together' do
      before do
        test_suite.add_test_case(test_case_success)
        test_suite.add_test_case(test_case_failed)
      end

      it 'returns a new test suite' do
        expect(subject).to be_an_instance_of(described_class)
      end

      it 'returns the suite name' do
        expect(subject.name).to eq('Rspec')
      end

      it 'returns the sum for total_time' do
        expect(subject.total_time).to eq(3.33)
      end

      it 'merges tests cases hash', :aggregate_failures do
        test_suite_2.add_test_case(create_test_case_java_success)

        failed_keys  = test_suite.test_cases['failed'].keys
        success_keys = test_suite.test_cases['success'].keys + test_suite_2.test_cases['success'].keys

        expect(subject.test_cases['failed'].keys).to contain_exactly(*failed_keys)
        expect(subject.test_cases['success'].keys).to contain_exactly(*success_keys)
      end
    end
  end

  describe '#sorted' do
    subject { test_suite.sorted }

    context 'when there are multiple failed test cases' do
      before do
        test_suite.add_test_case(create_test_case_rspec_failed('test_spec_1', 1.11))
        test_suite.add_test_case(create_test_case_rspec_failed('test_spec_2', 4.44))
      end

      it 'returns test cases sorted by execution time desc' do
        expect(subject.test_cases['failed'].each_value.first.execution_time).to eq(4.44)
        expect(subject.test_cases['failed'].values.second.execution_time).to eq(1.11)
      end
    end

    context 'when there are multiple test cases' do
      let(:status_ordered) { %w[error failed success skipped] }

      before do
        test_suite.add_test_case(test_case_success)
        test_suite.add_test_case(test_case_failed)
        test_suite.add_test_case(test_case_error)
        test_suite.add_test_case(test_case_skipped)
      end

      it 'returns test cases sorted by status' do
        expect(subject.test_cases.keys).to eq(status_ordered)
      end
    end
  end

  Gitlab::Ci::Reports::TestCase::STATUS_TYPES.each do |status_type|
    describe "##{status_type}" do
      subject { test_suite.public_send(status_type.to_s) }

      context "when #{status_type} test case exists" do
        before do
          test_suite.add_test_case(public_send("test_case_#{status_type}"))
        end

        it 'returns all success test cases' do
          is_expected.to eq({ public_send("test_case_#{status_type}").key => public_send("test_case_#{status_type}") })
        end
      end

      context "when #{status_type} test case do not exist" do
        it 'returns nothing' do
          is_expected.to be_empty
        end
      end
    end
  end

  describe '#each_test_case' do
    before do
      test_suite.add_test_case(test_case_success)
      test_suite.add_test_case(test_case_failed)
      test_suite.add_test_case(test_case_skipped)
      test_suite.add_test_case(test_case_error)
    end

    it 'yields each test case to given block' do
      expect { |b| test_suite.each_test_case(&b) }
        .to yield_successive_args(test_case_success, test_case_failed, test_case_skipped, test_case_error)
    end
  end

  Gitlab::Ci::Reports::TestCase::STATUS_TYPES.each do |status_type|
    describe "##{status_type}_count" do
      subject { test_suite.public_send("#{status_type}_count") }

      context "when #{status_type} test case exists" do
        before do
          test_suite.add_test_case(public_send("test_case_#{status_type}"))
        end

        it 'returns the count' do
          is_expected.to eq(1)
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
