# frozen_string_literal: true

require 'spec_helper'
require_migration!('cleanup_transfered_projects_shared_runners')

RSpec.describe CleanupTransferedProjectsSharedRunners, :sidekiq, schema: 20201110161542 do
  let(:namespaces) { table(:namespaces) }
  let(:migration) { described_class.new }
  let(:batch_interval) { described_class::INTERVAL }

  let!(:namespace_1) { namespaces.create!(name: 'foo', path: 'foo') }
  let!(:namespace_2) { namespaces.create!(name: 'bar', path: 'bar') }
  let!(:namespace_3) { namespaces.create!(name: 'baz', path: 'baz') }

  describe '#up' do
    before do
      stub_const("#{described_class}::BATCH_SIZE", 2)
    end

    it 'schedules ResetSharedRunnersForTransferredProjects background jobs' do
      Sidekiq::Testing.fake! do
        freeze_time do
          migration.up

          expect(BackgroundMigrationWorker.jobs.size).to eq(2)
          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(batch_interval, namespace_1.id, namespace_2.id)
          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(batch_interval * 2, namespace_3.id, namespace_3.id)
        end
      end
    end
  end
end
