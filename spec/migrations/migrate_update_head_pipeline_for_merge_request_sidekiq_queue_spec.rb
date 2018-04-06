require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180307012445_migrate_update_head_pipeline_for_merge_request_sidekiq_queue.rb')

describe MigrateUpdateHeadPipelineForMergeRequestSidekiqQueue, :sidekiq, :redis do
  include Gitlab::Database::MigrationHelpers

  context 'when there are jobs in the queues' do
    it 'correctly migrates queue when migrating up' do
      Sidekiq::Testing.disable! do
        stubbed_worker(queue: 'pipeline_default:update_head_pipeline_for_merge_request').perform_async('Something', [1])
        stubbed_worker(queue: 'pipeline_processing:update_head_pipeline_for_merge_request').perform_async('Something', [1])

        described_class.new.up

        expect(sidekiq_queue_length('pipeline_default:update_head_pipeline_for_merge_request')).to eq 0
        expect(sidekiq_queue_length('pipeline_processing:update_head_pipeline_for_merge_request')).to eq 2
      end
    end

    it 'does not affect other queues under the same namespace' do
      Sidekiq::Testing.disable! do
        stubbed_worker(queue: 'pipeline_default:build_coverage').perform_async('Something', [1])
        stubbed_worker(queue: 'pipeline_default:build_trace_sections').perform_async('Something', [1])
        stubbed_worker(queue: 'pipeline_default:pipeline_metrics').perform_async('Something', [1])
        stubbed_worker(queue: 'pipeline_default:pipeline_notification').perform_async('Something', [1])

        described_class.new.up

        expect(sidekiq_queue_length('pipeline_default:build_coverage')).to eq 1
        expect(sidekiq_queue_length('pipeline_default:build_trace_sections')).to eq 1
        expect(sidekiq_queue_length('pipeline_default:pipeline_metrics')).to eq 1
        expect(sidekiq_queue_length('pipeline_default:pipeline_notification')).to eq 1
      end
    end

    it 'correctly migrates queue when migrating down' do
      Sidekiq::Testing.disable! do
        stubbed_worker(queue: 'pipeline_processing:update_head_pipeline_for_merge_request').perform_async('Something', [1])

        described_class.new.down

        expect(sidekiq_queue_length('pipeline_default:update_head_pipeline_for_merge_request')).to eq 1
        expect(sidekiq_queue_length('pipeline_processing:update_head_pipeline_for_merge_request')).to eq 0
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
