# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UpdateContainerRegistryInfoWorker, feature_category: :container_registry do
  describe '#perform' do
    it 'calls UpdateContainerRegistryInfoService' do
      expect_next_instance_of(UpdateContainerRegistryInfoService) do |service|
        expect(service).to receive(:execute)
      end

      subject.perform
    end
  end
end
