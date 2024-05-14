# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineCreation::StartPipelineService, feature_category: :continuous_integration do
  let(:pipeline) { build(:ci_pipeline) }

  subject(:service) { described_class.new(pipeline) }

  describe '#execute' do
    it 'enqueues UpdateBuildNamesWorker' do
      expect(Ci::UpdateBuildNamesWorker).to receive(:perform_async).with(pipeline.id)

      service.execute
    end

    context 'when FF populate_and_use_build_names_table is disabled' do
      before do
        stub_feature_flags(populate_and_use_build_names_table: false)
      end

      it 'does not enqueue UpdateBuildNamesWorker' do
        expect(Ci::UpdateBuildNamesWorker).not_to receive(:perform_async)

        service.execute
      end
    end

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
  end
end
