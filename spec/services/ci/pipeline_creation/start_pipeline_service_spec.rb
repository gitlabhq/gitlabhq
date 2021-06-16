# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineCreation::StartPipelineService do
  let(:pipeline) { build(:ci_pipeline) }

  subject(:service) { described_class.new(pipeline) }

  describe '#execute' do
    it 'calls the pipeline process service' do
      expect(Ci::ProcessPipelineService)
        .to receive(:new)
        .with(pipeline)
        .and_return(double('service', execute: true))

      service.execute
    end
  end
end
