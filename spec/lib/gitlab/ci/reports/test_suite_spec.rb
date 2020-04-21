# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Reports::TestSuite do
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
    end

    it { is_expected.to eq(2) }
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
      let(:test_case) { build(:test_case, :failed)}

      before do
        test_suite.add_test_case(test_case)
      end

      it 'returns an empty hash' do
        expect(subject).to be_empty
      end
    end

    context 'when test cases contain an attachment' do
      let(:test_case_with_attachment) { build(:test_case, :with_attachment)}

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

  Gitlab::Ci::Reports::TestCase::STATUS_TYPES.each do |status_type|
    describe "##{status_type}" do
      subject { test_suite.public_send("#{status_type}") }

      context "when #{status_type} test case exists" do
        before do
          test_suite.add_test_case(public_send("test_case_#{status_type}"))
        end

        it 'returns all success test cases' do
          is_expected.to eq( { public_send("test_case_#{status_type}").key => public_send("test_case_#{status_type}") })
        end
      end

      context "when #{status_type} test case do not exist" do
        it 'returns nothing' do
          is_expected.to be_empty
        end
      end
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
