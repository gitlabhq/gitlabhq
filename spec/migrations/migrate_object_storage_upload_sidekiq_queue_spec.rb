require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180603190921_migrate_object_storage_upload_sidekiq_queue.rb')

describe MigrateObjectStorageUploadSidekiqQueue, :sidekiq, :redis do
  include Gitlab::Database::MigrationHelpers

  context 'when there are jobs in the queue' do
    it 'correctly migrates queue when migrating up' do
      Sidekiq::Testing.disable! do
        stubbed_worker(queue: 'object_storage_upload').perform_async('Something', [1])
        stubbed_worker(queue: 'object_storage:object_storage_background_move').perform_async('Something', [1])

        described_class.new.up

        expect(sidekiq_queue_length('object_storage_upload')).to eq 0
        expect(sidekiq_queue_length('object_storage:object_storage_background_move')).to eq 2
      end
    end
  end

  context 'when there are no jobs in the queues' do
    it 'does not raise error when migrating up' do
      expect { described_class.new.up }.not_to raise_error
    end
  end

  def stubbed_worker(queue:)
    Class.new do
      include Sidekiq::Worker
      sidekiq_options queue: queue
    end
  end
end
