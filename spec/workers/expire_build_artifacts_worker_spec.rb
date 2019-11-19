# frozen_string_literal: true

require 'spec_helper'

describe ExpireBuildArtifactsWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    it 'executes a service' do
      expect_any_instance_of(Ci::DestroyExpiredJobArtifactsService).to receive(:execute)

      worker.perform
    end
  end
end
