require 'spec_helper'

describe Integrations::PipelineService, services: true do
  let(:project) { create(:empty_project) }
  let(:service) { described_class.new(project, nil, params) }
  let(:pipeline) { create(:ci_pipeline_without_jobs, project: project) }

  subject { service.execute }

  describe '#execute' do
    context 'lookup by ref' do
      let(:params) { { text: pipeline.ref } }

      it 'returns the pipeline by ID' do
        expect(subject[:attachments].first[:fallback]).to match /Pipeline\ for\ #{pipeline.ref}: #{pipeline.status}/
      end
    end
  end
end
