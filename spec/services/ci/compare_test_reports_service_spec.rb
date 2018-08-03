require 'spec_helper'

describe Ci::CompareTestReportsService do
  let(:service) { described_class.new(project) }
  let(:project) { create(:project, :repository) }
  let(:merge_request) { create(:merge_request, source_project: project) }

  describe '#execute' do
    subject { service.execute(base_pipeline.iid, head_pipeline.iid) }

    let!(:base_pipeline) do
      create(:ci_pipeline,
        :success,
        project: merge_request.source_project,
        ref: merge_request.source_branch,
        sha: merge_request.diff_base_sha).tap do |pipeline|
        merge_request.update!(head_pipeline_id: pipeline.id)
        create(:ci_build, name: 'rspec', pipeline: pipeline, project: project)
      end
    end

    let!(:head_pipeline) do
      create(:ci_pipeline,
        :success,
        project: merge_request.source_project,
        ref: merge_request.source_branch,
        sha: merge_request.diff_head_sha).tap do |pipeline|
        merge_request.update!(head_pipeline_id: pipeline.id)
        create(:ci_build, name: 'rspec', pipeline: pipeline, project: project)
      end
    end

    context 'when head pipeline has test reports' do
      before do
        create(:ci_job_artifact, :junit, job: head_pipeline.builds.first, project: project)
      end

      it 'returns status and data' do
        expect(subject[:status]).to eq(:parsed)
        expect(subject[:data]).to match_schema('entities/test_reports_comparer')
      end
    end

    context 'when head pipeline has corrupted test reports' do
      before do
        create(:ci_job_artifact, :junit_with_corrupted_data, job: head_pipeline.builds.first, project: project)
      end

      it 'returns status and error message' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:status_reason]).to eq('Failed to parse XML')
      end
    end
  end
end
