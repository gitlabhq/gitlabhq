# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PipelineArtifacts::ExpireArtifactsWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let_it_be(:pipeline_artifact) do
      create(:ci_pipeline_artifact, :with_coverage_report, :unlocked, expire_at: 1.week.ago)
    end

    it 'executes a service' do
      expect_next_instance_of(::Ci::PipelineArtifacts::DestroyAllExpiredService) do |instance|
        expect(instance).to receive(:execute)
      end

      worker.perform
    end

    include_examples 'an idempotent worker' do
      subject do
        perform_multiple(worker: worker)
      end

      it 'removes the artifact only once' do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:destroyed_pipeline_artifacts_count, 1)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:destroyed_pipeline_artifacts_count, 0)

        subject

        expect { pipeline_artifact.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
