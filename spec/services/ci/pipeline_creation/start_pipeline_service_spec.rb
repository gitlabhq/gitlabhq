# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineCreation::StartPipelineService, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }
  let(:sha) { project.repository.commit.sha }
  let(:pipeline) { create(:ci_pipeline, sha: sha, project: project) }

  subject(:service) { described_class.new(pipeline) }

  describe '#execute' do
    it 'enqueues UpdateBuildNamesWorker' do
      expect(Ci::UpdateBuildNamesWorker).to receive(:perform_async).with(pipeline.id)

      service.execute
    end

    it 'calls the pipeline process service' do
      expect(Ci::ProcessPipelineService)
        .to receive(:new)
        .with(pipeline)
        .and_return(double('service', execute: true))

      service.execute
    end

    it 'creates pipeline ref' do
      expect { service.execute }
        .to change { pipeline.reload.persistent_ref.exist? }.to(true)
    end

    context 'when pipeline ref exists' do
      before do
        pipeline.persistent_ref.create # rubocop:disable Rails/SaveBang -- not AR instance
      end

      it 'does not create pipeline ref' do
        expect(pipeline.persistent_ref).not_to receive(:create)
        expect { service.execute }
          .not_to change { pipeline.reload.persistent_ref.exist? }.from(true)
      end
    end

    context 'when fail to create pipeline ref' do
      let(:sha) { 'unknown' }

      it 'drops pipeline' do
        expect { service.execute }
          .to change { pipeline.reload.status }.to('failed')
          .and change { pipeline.reload.failure_reason }.to('pipeline_ref_creation_failure')
      end
    end

    it 'calls ProjectWithPipelineVariablei.upsert_for_pipeline' do
      expect(Ci::ProjectWithPipelineVariable)
        .to receive(:upsert_for_pipeline)
        .with(pipeline).and_call_original

      service.execute
    end
  end
end
