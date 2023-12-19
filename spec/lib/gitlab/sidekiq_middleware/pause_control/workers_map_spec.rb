# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::PauseControl::WorkersMap, feature_category: :global_search do
  let(:worker_class) do
    Class.new do
      def self.name
        'TestPauseWorker'
      end

      include ApplicationWorker

      pause_control :zoekt

      def perform(*); end
    end
  end

  before do
    stub_const('TestPauseWorker', worker_class)
  end

  describe '.strategy_for' do
    it 'accepts classname' do
      expect(described_class.strategy_for(worker: worker_class)).to eq(:zoekt)
    end

    it 'accepts worker instance' do
      expect(described_class.strategy_for(worker: worker_class.new)).to eq(:zoekt)
    end

    it 'returns nil for unknown worker' do
      expect(described_class.strategy_for(worker: described_class)).to be_nil
    end
  end
end
