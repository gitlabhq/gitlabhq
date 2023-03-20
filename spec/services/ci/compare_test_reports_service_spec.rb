# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CompareTestReportsService, feature_category: :continuous_integration do
  let(:service) { described_class.new(project) }
  let(:project) { create(:project, :repository) }

  describe '#execute' do
    subject(:comparison) { service.execute(base_pipeline, head_pipeline) }

    context 'when head pipeline has test reports' do
      let!(:base_pipeline) { nil }
      let!(:head_pipeline) { create(:ci_pipeline, :with_test_reports, project: project) }

      it 'returns status and data' do
        expect(comparison[:status]).to eq(:parsed)
        expect(comparison[:data]).to match_schema('entities/test_reports_comparer')
      end
    end

    context 'when base and head pipelines have test reports' do
      let!(:base_pipeline) { create(:ci_pipeline, :with_test_reports, project: project) }
      let!(:head_pipeline) { create(:ci_pipeline, :with_test_reports, project: project) }

      it 'returns status and data' do
        expect(comparison[:status]).to eq(:parsed)
        expect(comparison[:data]).to match_schema('entities/test_reports_comparer')
      end
    end

    context 'when head pipeline has corrupted test reports' do
      let!(:base_pipeline) { nil }
      let!(:head_pipeline) { create(:ci_pipeline, project: project) }

      before do
        build = create(:ci_build, pipeline: head_pipeline, project: head_pipeline.project)
        create(:ci_job_artifact, :junit_with_corrupted_data, job: build, project: project)
      end

      it 'returns a parsed TestReports success status and failure on the individual suite' do
        expect(comparison[:status]).to eq(:parsed)
        expect(comparison.dig(:data, 'status')).to eq('success')
        expect(comparison.dig(:data, 'suites', 0, 'status')).to eq('error')
      end
    end

    context 'test failure history' do
      let!(:base_pipeline) { nil }
      let!(:head_pipeline) { create(:ci_pipeline, :with_test_reports_with_three_failures, project: project) }

      let(:new_failures) do
        comparison.dig(:data, 'suites', 0, 'new_failures')
      end

      let(:recent_failures_per_test_case) do
        new_failures.map { |f| f['recent_failures'] }
      end

      # Create test case failure records based on the head pipeline build
      before do
        stub_const("Gitlab::Ci::Reports::TestSuiteComparer::DEFAULT_MAX_TESTS", 2)
        stub_const("Gitlab::Ci::Reports::TestSuiteComparer::DEFAULT_MIN_TESTS", 1)

        build = head_pipeline.builds.last
        build.update_column(:finished_at, 1.day.ago) # Just to be sure we are included in the report window

        # The JUnit fixture for the given build has 3 failures.
        # This service will create 1 test case failure record for each.
        Ci::TestFailureHistoryService.new(head_pipeline).execute
      end

      it 'loads recent failures on limited test cases to avoid building up a huge DB query', :aggregate_failures do
        expect(comparison[:data]).to match_schema('entities/test_reports_comparer')
        expect(recent_failures_per_test_case).to eq(
          [
            { 'count' => 1, 'base_branch' => 'master' },
            { 'count' => 1, 'base_branch' => 'master' }
          ])
        expect(new_failures.count).to eq(2)
      end
    end
  end
end
