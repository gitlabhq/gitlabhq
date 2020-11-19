# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TestCasesService, :aggregate_failures do
  describe '#execute' do
    subject(:execute_service) { described_class.new.execute(build) }

    context 'when build has test reports' do
      let(:build) { create(:ci_build, :success, :test_reports) } # The test report has 2 test case failures

      it 'creates test case failures records' do
        execute_service

        expect(Ci::TestCase.count).to eq(2)
        expect(Ci::TestCaseFailure.count).to eq(2)
      end

      context 'when feature flag for test failure history is disabled' do
        before do
          stub_feature_flags(test_failure_history: false)
        end

        it 'does not persist data' do
          execute_service

          expect(Ci::TestCase.count).to eq(0)
          expect(Ci::TestCaseFailure.count).to eq(0)
        end
      end

      context 'when build is not for the default branch' do
        before do
          build.update_column(:ref, 'new-feature')
        end

        it 'does not persist data' do
          execute_service

          expect(Ci::TestCase.count).to eq(0)
          expect(Ci::TestCaseFailure.count).to eq(0)
        end
      end

      context 'when test failure data have already been persisted with the same exact attributes' do
        before do
          execute_service
        end

        it 'does not fail but does not persist new data' do
          expect { described_class.new.execute(build) }.not_to raise_error

          expect(Ci::TestCase.count).to eq(2)
          expect(Ci::TestCaseFailure.count).to eq(2)
        end
      end

      context 'when test failure data have duplicates within the same payload (happens when the JUnit report has duplicate test case names but have different failures)' do
        let(:build) { create(:ci_build, :success, :test_reports_with_duplicate_failed_test_names) } # The test report has 2 test case failures but with the same test case keys

        it 'does not fail but does not persist duplicate data' do
          expect { described_class.new.execute(build) }.not_to raise_error

          expect(Ci::TestCase.count).to eq(1)
          expect(Ci::TestCaseFailure.count).to eq(1)
        end
      end

      context 'when number of failed test cases exceed the limit' do
        before do
          stub_const("#{described_class.name}::MAX_TRACKABLE_FAILURES", 1)
        end

        it 'does not persist data' do
          execute_service

          expect(Ci::TestCase.count).to eq(0)
          expect(Ci::TestCaseFailure.count).to eq(0)
        end
      end
    end

    context 'when build has no test reports' do
      let(:build) { create(:ci_build, :running) }

      it 'does not persist data' do
        execute_service

        expect(Ci::TestCase.count).to eq(0)
        expect(Ci::TestCaseFailure.count).to eq(0)
      end
    end
  end
end
