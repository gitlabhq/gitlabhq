# frozen_string_literal: true

require 'spec_helper'
require_migration!('backfill_project_settings')

RSpec.describe BackfillProjectSettings, :sidekiq, schema: 20200114113341 do
  let(:projects) { table(:projects) }
  let(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }
  let(:project) { projects.create!(namespace_id: namespace.id) }

  describe '#up' do
    before do
      stub_const("#{described_class}::BATCH_SIZE", 2)

      projects.create!(id: 1, namespace_id: namespace.id)
      projects.create!(id: 2, namespace_id: namespace.id)
      projects.create!(id: 3, namespace_id: namespace.id)
    end

    it 'schedules BackfillProjectSettings background jobs' do
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
