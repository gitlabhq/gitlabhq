# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20200206111847_migrate_propagate_service_template_sidekiq_queue.rb')

describe MigratePropagateServiceTemplateSidekiqQueue, :sidekiq, :redis do
  include Gitlab::Database::MigrationHelpers
  include StubWorker

  context 'when there are jobs in the queue' do
    it 'correctly migrates queue when migrating up' do
      Sidekiq::Testing.disable! do
        stub_worker(queue: 'propagate_service_template').perform_async('Something', [1])
        stub_worker(queue: 'propagate_instance_level_service').perform_async('Something', [1])

        described_class.new.up

        expect(sidekiq_queue_length('propagate_service_template')).to eq 0
        expect(sidekiq_queue_length('propagate_instance_level_service')).to eq 2
      end
    end
  end

  context 'when there are no jobs in the queues' do
    it 'does not raise error when migrating up' do
      expect { described_class.new.up }.not_to raise_error
    end
  end
end
