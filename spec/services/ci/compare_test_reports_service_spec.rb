# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CompareTestReportsService, feature_category: :continuous_integration do
  let(:service) { described_class.new(project, user) }
  let_it_be(:project) { create(:project, :repository) }
  # get_report scopes to what the user may read; use a maintainer so the
  # comparison examples see the reports (access control is covered separately).
  let_it_be(:user) { create(:user, maintainer_of: project) }

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

    context 'when the head pipeline has a maintainer-only test report' do
      let_it_be(:maintainer) { create(:user, maintainer_of: project) }
      let_it_be(:guest) { create(:user, guest_of: project) }

      let!(:base_pipeline) { nil }
      let!(:head_pipeline) { create(:ci_pipeline, project: project) }

      before do
        build = create(:ci_build, :success, pipeline: head_pipeline, project: project)
        # Reports-only job: maintainer-only JUnit report with no archive, so the
        # report's own accessibility gates the MR widget comparison.
        create(:ci_job_artifact, :junit, :maintainer_only_access, job: build, project: project)
      end

      it 'excludes the report from a user without artifact access' do
        comparison = described_class.new(project, guest).execute(base_pipeline, head_pipeline)

        expect(comparison.dig(:data, 'summary', 'total')).to eq(0)
      end

      it 'includes the report for a user who can read maintainer artifacts' do
        comparison = described_class.new(project, maintainer).execute(base_pipeline, head_pipeline)

        expect(comparison.dig(:data, 'summary', 'total')).to be > 0
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
