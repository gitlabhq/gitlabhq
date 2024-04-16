# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Migration::GuardWorker, :aggregate_failures, feature_category: :container_registry do
  let(:worker) { described_class.new }

  describe '#perform' do
    it 'is a no op' do
      expect { worker.perform }.not_to raise_error
    end
  end

  describe 'worker attributes' do
    it 'has deduplication set' do
      expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
      expect(described_class.get_deduplication_options).to include(ttl: 5.minutes)
    end
  end
end
