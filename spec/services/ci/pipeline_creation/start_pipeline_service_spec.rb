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

    it 'creates pipeline ref' do
      expect(pipeline.persistent_ref).to receive(:create).once

      service.execute
    end

    context 'when ci_reduce_persistent_ref_writes feature flag is disabled' do
      before do
        stub_feature_flags(ci_reduce_persistent_ref_writes: false)
      end

      it 'does not populate pipeline ref' do
        expect(pipeline.persistent_ref).not_to receive(:create)

        service.execute
      end
    end
  end
end
