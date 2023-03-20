# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ProcessPipelineService, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }

  let(:pipeline) do
    create(:ci_empty_pipeline, ref: 'master', project: project)
  end

  let(:pipeline_processing_events_counter) { double(increment: true) }

  let(:metrics) do
    double(pipeline_processing_events_counter: pipeline_processing_events_counter)
  end

  subject { described_class.new(pipeline) }

  before do
    stub_ci_pipeline_to_return_yaml_file
    stub_not_protect_default_branch

    allow(subject).to receive(:metrics).and_return(metrics)
  end

  describe 'processing events counter' do
    it 'increments processing events counter' do
      expect(pipeline_processing_events_counter).to receive(:increment)

      subject.execute
    end
  end
end
