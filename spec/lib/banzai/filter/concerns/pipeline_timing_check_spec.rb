# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::Concerns::PipelineTimingCheck, feature_category: :team_planning do
  context 'when pipeline_timing' do
    before do
      stub_const('Banzai::Filter::Concerns::PipelineTimingCheck::MAX_PIPELINE_SECONDS', 1)
      stub_const('PipelineTest', Class.new(HTML::Pipeline::Filter))
      PipelineTest.class_eval { include Banzai::Filter::Concerns::PipelineTimingCheck }
    end

    let(:described_class) { PipelineTest }

    it 'returns true if MAX_PIPELINE_SECONDS exceeded' do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:result).and_return({ pipeline_timing: 1.1 })
      end

      expect(described_class.new('text').exceeded_pipeline_max?).to be_truthy
    end

    it 'returns false if MAX_PIPELINE_SECONDS not exceeded' do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:result).and_return({ pipeline_timing: 0.9 })
      end

      expect(described_class.new('text').exceeded_pipeline_max?).to be_falsey
    end
  end
end
