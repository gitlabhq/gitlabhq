# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Migration::EnqueuerWorker, feature_category: :container_registry do
  let(:worker) { described_class.new }

  describe '#perform' do
    it 'is a no op' do
      expect { worker.perform }.not_to raise_error
    end
  end

  describe 'worker attributes' do
    it 'has deduplication set' do
      expect(described_class.get_deduplicate_strategy).to eq(:until_executing)
      expect(described_class.get_deduplication_options).to include(ttl: 30.minutes)
    end
  end
end
