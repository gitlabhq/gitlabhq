# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TestFailureHistoryService, :aggregate_failures do
  describe '#execute' do
    let(:project) { create(:project) }
    let(:pipeline) { create(:ci_empty_pipeline, status: :created, project: project) }

    subject(:execute_service) { described_class.new(pipeline).execute }

    context 'when pipeline has failed builds with test reports' do
      before do
        # The test report has 2 unit test failures
        create(:ci_build, :failed, :test_reports, pipeline: pipeline, project: project)
      end

      it 'creates unit test failures records' do
        execute_service

        expect(Ci::UnitTest.count).to eq(2)
        expect(Ci::UnitTestFailure.count).to eq(2)
      end

      context 'when pipeline is not for the default branch' do
        before do
          pipeline.update_column(:ref, 'new-feature')
        end

        it 'does not persist data' do
          execute_service

          expect(Ci::UnitTest.count).to eq(0)
          expect(Ci::UnitTestFailure.count).to eq(0)
        end
      end

      context 'when test failure data have already been persisted with the same exact attributes' do
        before do
          execute_service
        end

        it 'does not fail but does not persist new data' do
          expect { described_class.new(pipeline).execute }.not_to raise_error

          expect(Ci::UnitTest.count).to eq(2)
          expect(Ci::UnitTestFailure.count).to eq(2)
        end
      end

      context 'when number of failed unit tests exceed the limit' do
        before do
          stub_const("#{described_class.name}::MAX_TRACKABLE_FAILURES", 1)
        end

        it 'does not persist data' do
          execute_service

          expect(Ci::UnitTest.count).to eq(0)
          expect(Ci::UnitTestFailure.count).to eq(0)
        end
      end

      context 'when number of failed unit tests across multiple builds exceed the limit' do
        before do
          stub_const("#{described_class.name}::MAX_TRACKABLE_FAILURES", 2)

          # This other test report has 1 unique unit test failure which brings us to 3 total failures across all builds
          # thus exceeding the limit of 2 for MAX_TRACKABLE_FAILURES
          create(:ci_build, :failed, :test_reports_with_duplicate_failed_test_names, pipeline: pipeline, project: project)
        end

        it 'does not persist data' do
          execute_service

          expect(Ci::UnitTest.count).to eq(0)
          expect(Ci::UnitTestFailure.count).to eq(0)
        end
      end
    end

    context 'when test failure data have duplicates within the same payload (happens when the JUnit report has duplicate unit test names but have different failures)' do
      before do
        # The test report has 2 unit test failures but with the same unit test keys
        create(:ci_build, :failed, :test_reports_with_duplicate_failed_test_names, pipeline: pipeline, project: project)
      end

      it 'does not fail but does not persist duplicate data' do
        expect { execute_service }.not_to raise_error

        expect(Ci::UnitTest.count).to eq(1)
        expect(Ci::UnitTestFailure.count).to eq(1)
      end
    end

    context 'when pipeline has no failed builds with test reports' do
      before do
        create(:ci_build, :test_reports, pipeline: pipeline, project: project)
        create(:ci_build, :failed, pipeline: pipeline, project: project)
      end

      it 'does not persist data' do
        execute_service

        expect(Ci::UnitTest.count).to eq(0)
        expect(Ci::UnitTestFailure.count).to eq(0)
      end
    end
  end

  describe '#should_track_failures?' do
    let(:project) { create(:project, :repository) }
    let(:pipeline) { create(:ci_empty_pipeline, status: :created, project: project, ref: project.default_branch) }

    subject { described_class.new(pipeline).should_track_failures? }

    before do
      create(:ci_build, :test_reports, :failed, pipeline: pipeline, project: project)
      create(:ci_build, :test_reports, :failed, pipeline: pipeline, project: project)
    end

    context 'when feature flag is enabled and pipeline ref is the default branch' do
      it { is_expected.to eq(true) }
    end

    context 'when pipeline is not equal to the project default branch' do
      before do
        pipeline.update_column(:ref, 'some-other-branch')
      end

      it { is_expected.to eq(false) }
    end

    context 'when total number of builds with failed tests exceeds the max number of trackable failures' do
      before do
        stub_const("#{described_class.name}::MAX_TRACKABLE_FAILURES", 1)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '#async' do
    let(:pipeline) { double(id: 1) }
    let(:service) { described_class.new(pipeline) }

    context 'when service should track failures' do
      before do
        allow(service).to receive(:should_track_failures?).and_return(true)
      end

      it 'enqueues the worker when #perform_if_needed is called' do
        expect(Ci::TestFailureHistoryWorker).to receive(:perform_async).with(pipeline.id)

        service.async.perform_if_needed
      end
    end

    context 'when service should not track failures' do
      before do
        allow(service).to receive(:should_track_failures?).and_return(false)
      end

      it 'does not enqueue the worker when #perform_if_needed is called' do
        expect(Ci::TestFailureHistoryWorker).not_to receive(:perform_async)

        service.async.perform_if_needed
      end
    end
  end
end
