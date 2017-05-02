require 'spec_helper'

describe Ci::ExpirePipelineCacheService, services: true do
  let(:project) { pipeline.project }
  let(:pipeline) { create(:ci_pipeline) }

  before do
    stub_ci_pipeline_to_return_yaml_file
  end

  subject { described_class.new(project, nil).execute(pipeline) }

  describe '#execute' do
    it 'creates a new Store' do
      expect(Gitlab::EtagCaching::Store).to receive(:new)
        .and_call_original

      subject
    end

    it 'updates the ProjectPipelineStatus cache' do
      expect(Gitlab::Cache::Ci::ProjectPipelineStatus)
        .to receive(:update_for_pipeline).with(pipeline)

      subject
    end
  end
end
