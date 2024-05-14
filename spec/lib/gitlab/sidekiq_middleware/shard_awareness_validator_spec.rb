# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::ShardAwarenessValidator, feature_category: :scalability do
  let(:worker) do
    Class.new do
      def self.name
        'TestWorker'
      end

      def perform
        Thread.current[:validate_sidekiq_shard_awareness]
      end
      include ApplicationWorker
    end
  end

  around do |example|
    original_state = Thread.current[:validate_sidekiq_shard_awareness]
    Thread.current[:validate_sidekiq_shard_awareness] = nil

    with_sidekiq_server_middleware do |chain|
      chain.add described_class
      Sidekiq::Testing.inline! { example.run }
    end

    Thread.current[:validate_sidekiq_shard_awareness] = original_state
  end

  subject { described_class.new }

  before do
    stub_const('TestWorker', worker)
  end

  describe '#call' do
    it 'validates shard-aware calls within a middleware' do
      expect { Sidekiq.redis(&:ping) }.not_to raise_error

      # .perform_async prevents an error from being raised
      expect(TestWorker.perform_async).to be_truthy
    end
  end
end
