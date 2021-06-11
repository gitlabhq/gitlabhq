# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SchedulePagesMetadataMigration do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 1)

    namespaces.create!(id: 11, name: 'gitlab', path: 'gitlab-org')
    projects.create!(id: 111, namespace_id: 11, name: 'Project 111')
    projects.create!(id: 114, namespace_id: 11, name: 'Project 114')
  end

  it 'schedules pages metadata migration' do
    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(2.minutes, 111, 111)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(4.minutes, 114, 114)
        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end
end
