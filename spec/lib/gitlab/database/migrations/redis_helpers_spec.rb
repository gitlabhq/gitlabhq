# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Database::Migrations::RedisHelpers, feature_category: :redis do
  let(:migration) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  describe "#queue_redis_migration_job" do
    let(:job_name) { 'SampleJob' }

    subject { migration.queue_redis_migration_job(job_name) }

    context 'when migrator does not exist' do
      it 'raises error and fails the migration' do
        expect { subject }.to raise_error(NotImplementedError)
      end
    end

    context 'when migrator exists' do
      before do
        allow(RedisMigrationWorker).to receive(:fetch_migrator!)
      end

      it 'checks migrator and enqueues job' do
        expect(RedisMigrationWorker).to receive(:perform_async).with(job_name, '0')

        subject
      end
    end
  end
end
