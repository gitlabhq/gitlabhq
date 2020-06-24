# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExpireBuildArtifactsWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    it 'executes a service' do
      expect_next_instance_of(Ci::DestroyExpiredJobArtifactsService) do |instance|
        expect(instance).to receive(:execute)
      end

      worker.perform
    end
  end
end
