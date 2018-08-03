require 'spec_helper'

describe Ci::CompareTestReportsService do
  let(:service) { described_class.new(project) }
  let(:project) { create(:project, :repository) }

  describe '#execute' do
    subject { service.execute(base_pipeline&.iid, head_pipeline.iid) }

    context 'when head pipeline has test reports' do
      let!(:base_pipeline) { nil }
      let!(:head_pipeline) { create(:ci_pipeline, :with_test_reports, project: project) }

      it 'returns status and data' do
        expect(subject[:status]).to eq(:parsed)
        expect(subject[:data]).to match_schema('entities/test_reports_comparer')
      end
    end

    context 'when base and head pipelines have test reports' do
      let!(:base_pipeline) { create(:ci_pipeline, :with_test_reports, project: project) }
      let!(:head_pipeline) { create(:ci_pipeline, :with_test_reports, project: project) }

      it 'returns status and data' do
        expect(subject[:status]).to eq(:parsed)
        expect(subject[:data]).to match_schema('entities/test_reports_comparer')
      end
    end

    context 'when head pipeline has corrupted test reports' do
      let!(:base_pipeline) { nil }
      let!(:head_pipeline) { create(:ci_pipeline, project: project) }

      before do
        build = create(:ci_build, pipeline: head_pipeline, project: head_pipeline.project)
        create(:ci_job_artifact, :junit_with_corrupted_data, job: build, project: project)
      end

      it 'returns status and error message' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:status_reason]).to include('XML parsing failed')
      end
    end
  end
end
