require 'spec_helper'

describe Ci::Charts do
  context "pipeline_times" do
    let(:project) { create(:empty_project) }
    let(:chart) { Ci::Charts::PipelineTime.new(project) }

    subject { chart.pipeline_times }

    before do
      create(:ci_empty_pipeline, project: project, duration: 120)
    end

    it 'returns pipeline times in minutes' do
      is_expected.to contain_exactly(2)
    end

    it 'handles nil pipeline times' do
      create(:ci_empty_pipeline, project: project, duration: nil)

      is_expected.to contain_exactly(2, 0)
    end
  end
end
