require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170822101017_migrate_pipeline_sidekiq_queues.rb')

describe MigratePipelineSidekiqQueues, :sidekiq, :redis do
  include Gitlab::Database::MigrationHelpers

  context 'when there are jobs in the queues' do
    it 'correctly migrates queue when migrating up' do
      Sidekiq::Testing.disable! do
        stubbed_worker(queue: :pipeline).perform_async('Something', [1])
        stubbed_worker(queue: :build).perform_async('Something', [1])

        described_class.new.up

        expect(sidekiq_queue_length('pipeline')).to eq 0
        expect(sidekiq_queue_length('build')).to eq 0
        expect(sidekiq_queue_length('pipeline_default')).to eq 2
      end
    end

    it 'correctly migrates queue when migrating down' do
      Sidekiq::Testing.disable! do
        stubbed_worker(queue: :pipeline_default).perform_async('Class', [1])
        stubbed_worker(queue: :pipeline_processing).perform_async('Class', [2])
        stubbed_worker(queue: :pipeline_hooks).perform_async('Class', [3])
        stubbed_worker(queue: :pipeline_cache).perform_async('Class', [4])

        described_class.new.down

        expect(sidekiq_queue_length('pipeline')).to eq 4
        expect(sidekiq_queue_length('pipeline_default')).to eq 0
        expect(sidekiq_queue_length('pipeline_processing')).to eq 0
        expect(sidekiq_queue_length('pipeline_hooks')).to eq 0
        expect(sidekiq_queue_length('pipeline_cache')).to eq 0
      end
    end
  end

  context 'when there are no jobs in the queues' do
    it 'does not raise error when migrating up' do
      expect { described_class.new.up }.not_to raise_error
    end

    it 'does not raise error when migrating down' do
      expect { described_class.new.down }.not_to raise_error
    end
  end

  def stubbed_worker(queue:)
    Class.new do
      include Sidekiq::Worker
      sidekiq_options queue: queue
    end
  end
end
