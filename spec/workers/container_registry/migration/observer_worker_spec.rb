# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Migration::ObserverWorker, :aggregate_failures, feature_category: :container_registry do
  let(:worker) { described_class.new }

  describe '#perform' do
    it 'is a no op' do
      expect { worker.perform }.not_to raise_error
    end
  end
end
