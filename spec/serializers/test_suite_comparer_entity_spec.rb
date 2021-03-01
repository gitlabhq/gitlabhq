# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TestSuiteComparerEntity do
  include TestReportsHelper

  let(:entity) { described_class.new(comparer) }
  let(:comparer) { Gitlab::Ci::Reports::TestSuiteComparer.new(name, base_suite, head_suite) }
  let(:name) { 'rpsec' }
  let(:base_suite) { Gitlab::Ci::Reports::TestSuite.new(name) }
  let(:head_suite) { Gitlab::Ci::Reports::TestSuite.new(name) }
  let(:test_case_success) { create_test_case_rspec_success }
  let(:test_case_failed) { create_test_case_rspec_failed }
  let(:test_case_error) { create_test_case_rspec_error }

  describe '#as_json' do
    subject { entity.as_json }

    context 'when head suite has a newly failed test case which does not exist in base' do
      before do
        base_suite.add_test_case(test_case_success)
        head_suite.add_test_case(test_case_failed)
      end

      it 'contains correct compared test suite details' do
        expect(subject[:name]).to eq(name)
        expect(subject[:status]).to eq('failed')
        expect(subject[:summary]).to include(total: 1, resolved: 0, failed: 1, errored: 0)
        subject[:new_failures].first.tap do |new_failure|
          expect(new_failure[:status]).to eq(test_case_failed.status)
          expect(new_failure[:name]).to eq(test_case_failed.name)
          expect(new_failure[:execution_time]).to eq(test_case_failed.execution_time)
          expect(new_failure[:system_output]).to eq(test_case_failed.system_output)
        end
        expect(subject[:resolved_failures]).to be_empty
        expect(subject[:existing_failures]).to be_empty
        expect(subject[:suite_errors]).to be_nil
      end
    end

    context 'when head suite has a new error test case which does not exist in base' do
      before do
        base_suite.add_test_case(test_case_success)
        head_suite.add_test_case(test_case_error)
      end

      it 'contains correct compared test suite details' do
        expect(subject[:name]).to eq(name)
        expect(subject[:status]).to eq('failed')
        expect(subject[:summary]).to include(total: 1, resolved: 0, failed: 0, errored: 1)
        subject[:new_errors].first.tap do |new_error|
          expect(new_error[:status]).to eq(test_case_error.status)
          expect(new_error[:name]).to eq(test_case_error.name)
          expect(new_error[:execution_time]).to eq(test_case_error.execution_time)
          expect(new_error[:system_output]).to eq(test_case_error.system_output)
        end
        expect(subject[:resolved_failures]).to be_empty
        expect(subject[:existing_failures]).to be_empty
        expect(subject[:suite_errors]).to be_nil
      end
    end

    context 'when head suite still has a failed test case which failed in base' do
      before do
        base_suite.add_test_case(test_case_failed)
        head_suite.add_test_case(test_case_failed)
      end

      it 'contains correct compared test suite details' do
        expect(subject[:name]).to eq(name)
        expect(subject[:status]).to eq('failed')
        expect(subject[:summary]).to include(total: 1, resolved: 0, failed: 1, errored: 0)
        expect(subject[:new_failures]).to be_empty
        expect(subject[:resolved_failures]).to be_empty
        subject[:existing_failures].first.tap do |existing_failure|
          expect(existing_failure[:status]).to eq(test_case_failed.status)
          expect(existing_failure[:name]).to eq(test_case_failed.name)
          expect(existing_failure[:execution_time]).to eq(test_case_failed.execution_time)
          expect(existing_failure[:system_output]).to eq(test_case_failed.system_output)
        end
        expect(subject[:suite_errors]).to be_nil
      end
    end

    context 'when head suite has a success test case which failed in base' do
      before do
        base_suite.add_test_case(test_case_failed)
        head_suite.add_test_case(test_case_success)
      end

      it 'contains correct compared test suite details' do
        expect(subject[:name]).to eq(name)
        expect(subject[:status]).to eq('success')
        expect(subject[:summary]).to include(total: 1, resolved: 1, failed: 0, errored: 0)
        expect(subject[:new_failures]).to be_empty
        subject[:resolved_failures].first.tap do |resolved_failure|
          expect(resolved_failure[:status]).to eq(test_case_success.status)
          expect(resolved_failure[:name]).to eq(test_case_success.name)
          expect(resolved_failure[:execution_time]).to eq(test_case_success.execution_time)
          expect(resolved_failure[:system_output]).to eq(test_case_success.system_output)
        end
        expect(subject[:existing_failures]).to be_empty
        expect(subject[:suite_errors]).to be_nil
      end
    end

    context 'when head suite has suite error' do
      before do
        allow(head_suite).to receive(:suite_error).and_return('some error')
      end

      it 'contains suite error for head suite' do
        expect(subject[:suite_errors]).to eq(
          head: 'some error',
          base: nil
        )
      end
    end

    context 'when base suite has suite error' do
      before do
        allow(base_suite).to receive(:suite_error).and_return('some error')
      end

      it 'contains suite error for head suite' do
        expect(subject[:suite_errors]).to eq(
          head: nil,
          base: 'some error'
        )
      end
    end

    context 'when base and head suite both have suite errors' do
      before do
        allow(head_suite).to receive(:suite_error).and_return('head error')
        allow(base_suite).to receive(:suite_error).and_return('base error')
      end

      it 'contains suite error for head suite' do
        expect(subject[:suite_errors]).to eq(
          head: 'head error',
          base: 'base error'
        )
      end
    end
  end
end
