# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::UpdateLockedUnknownArtifactsWorker, feature_category: :job_artifacts do
  let(:worker) { described_class.new }

  describe '#perform' do
    it 'executes an instance of Ci::JobArtifacts::UpdateUnknownLockedStatusService' do
      expect_next_instance_of(Ci::JobArtifacts::UpdateUnknownLockedStatusService) do |instance|
        expect(instance).to receive(:execute).and_call_original
      end

      expect(worker).to receive(:log_extra_metadata_on_done).with(:removed_count, 0)
      expect(worker).to receive(:log_extra_metadata_on_done).with(:locked_count, 0)

      worker.perform
    end
  end
end
