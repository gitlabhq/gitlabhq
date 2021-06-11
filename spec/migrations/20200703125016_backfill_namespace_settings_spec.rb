# frozen_string_literal: true

require 'spec_helper'
require_migration!('backfill_namespace_settings')

RSpec.describe BackfillNamespaceSettings, :sidekiq, schema: 20200703124823 do
  let(:namespaces) { table(:namespaces) }

  describe '#up' do
    before do
      stub_const("#{described_class}::BATCH_SIZE", 2)

      namespaces.create!(id: 1, name: 'test1', path: 'test1')
      namespaces.create!(id: 2, name: 'test2', path: 'test2')
      namespaces.create!(id: 3, name: 'test3', path: 'test3')
    end

    it 'schedules BackfillNamespaceSettings background jobs' do
      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(2.minutes, 1, 2)
          expect(described_class::MIGRATION).to be_scheduled_delayed_migration(4.minutes, 3, 3)
          expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        end
      end
    end
  end
end
