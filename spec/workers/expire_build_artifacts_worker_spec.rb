# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExpireBuildArtifactsWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    it 'executes a service' do
      expect_next_instance_of(Ci::JobArtifacts::DestroyAllExpiredService) do |instance|
        expect(instance).to receive(:execute).and_call_original
      end

      expect(worker).to receive(:log_extra_metadata_on_done).with(:destroyed_job_artifacts_count, 0)

      worker.perform
    end
  end
end
