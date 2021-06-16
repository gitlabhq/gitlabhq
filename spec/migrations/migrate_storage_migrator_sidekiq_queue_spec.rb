# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateStorageMigratorSidekiqQueue, :redis do
  include Gitlab::Database::MigrationHelpers
  include StubWorker

  context 'when there are jobs in the queues' do
    it 'correctly migrates queue when migrating up' do
      Sidekiq::Testing.disable! do
        stub_worker(queue: :storage_migrator).perform_async(1, 5)

        described_class.new.up

        expect(sidekiq_queue_length('storage_migrator')).to eq 0
        expect(sidekiq_queue_length('hashed_storage:hashed_storage_migrator')).to eq 1
      end
    end

    it 'correctly migrates queue when migrating down' do
      Sidekiq::Testing.disable! do
        stub_worker(queue: :'hashed_storage:hashed_storage_migrator').perform_async(1, 5)

        described_class.new.down

        expect(sidekiq_queue_length('storage_migrator')).to eq 1
        expect(sidekiq_queue_length('hashed_storage:hashed_storage_migrator')).to eq 0
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
end
