# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateStoreSecurityReportsSidekiqQueue, :redis do
  include Gitlab::Database::MigrationHelpers
  include StubWorker

  context 'when there are jobs in the queue' do
    it 'migrates queue when migrating up' do
      Sidekiq::Testing.disable! do
        stub_worker(queue: 'pipeline_default:store_security_reports').perform_async(1, 5)

        described_class.new.up

        expect(sidekiq_queue_length('pipeline_default:store_security_reports')).to eq 0
        expect(sidekiq_queue_length('security_scans:store_security_reports')).to eq 1
      end
    end

    it 'migrates queue when migrating down' do
      Sidekiq::Testing.disable! do
        stub_worker(queue: 'security_scans:store_security_reports').perform_async(1, 5)

        described_class.new.down

        expect(sidekiq_queue_length('pipeline_default:store_security_reports')).to eq 1
        expect(sidekiq_queue_length('security_scans:store_security_reports')).to eq 0
      end
    end
  end
end
