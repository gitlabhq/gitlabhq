# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqDeathHandler, :clean_gitlab_redis_queues do
  describe '.handler' do
    context 'when the job class has worker attributes' do
      let(:test_worker) do
        Class.new do
          include WorkerAttributes

          urgency :low
          worker_has_external_dependencies!
          worker_resource_boundary :cpu
          feature_category :user_profile
        end
      end

      before do
        stub_const('TestWorker', test_worker)
      end

      it 'uses the attributes from the worker' do
        expect(described_class.counter)
          .to receive(:increment)
                .with({ queue: 'test_queue', worker: 'TestWorker',
                        urgency: 'low', external_dependencies: 'yes',
                        feature_category: 'user_profile', boundary: 'cpu', destination_shard_redis: 'main' })

        described_class.handler({ 'class' => 'TestWorker', 'queue' => 'test_queue' }, nil)
      end
    end

    context 'when the job class does not have worker attributes' do
      before do
        stub_const('TestWorker', Class.new)
      end

      it 'uses blank attributes' do
        expect(described_class.counter)
          .to receive(:increment)
                .with({ queue: 'test_queue', worker: 'TestWorker',
                        urgency: '', external_dependencies: 'no',
                        feature_category: '', boundary: '', destination_shard_redis: 'main' })

        described_class.handler({ 'class' => 'TestWorker', 'queue' => 'test_queue' }, nil)
      end
    end
  end
end
