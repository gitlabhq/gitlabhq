# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MoveContainerRegistryEnabledToProjectFeatures3, :migration do
  let(:namespace) { table(:namespaces).create!(name: 'gitlab', path: 'gitlab-org') }

  let!(:background_jobs) do
    table(:background_migration_jobs).create!(class_name: described_class::MIGRATION, arguments: [-1, -2])
    table(:background_migration_jobs).create!(class_name: described_class::MIGRATION, arguments: [-3, -4])
  end

  let!(:projects) do
    [
      table(:projects).create!(namespace_id: namespace.id, name: 'project 1'),
      table(:projects).create!(namespace_id: namespace.id, name: 'project 2'),
      table(:projects).create!(namespace_id: namespace.id, name: 'project 3'),
      table(:projects).create!(namespace_id: namespace.id, name: 'project 4')
    ]
  end

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 3)
  end

  around do |example|
    Sidekiq::Testing.fake! do
      freeze_time do
        example.call
      end
    end
  end

  it 'schedules jobs for ranges of projects' do
    # old entries in background_migration_jobs should be deleted.
    expect(table(:background_migration_jobs).count).to eq(2)
    expect(table(:background_migration_jobs).first.arguments).to eq([-1, -2])
    expect(table(:background_migration_jobs).second.arguments).to eq([-3, -4])

    migrate!

    # Since track_jobs is true, each job should have an entry in the background_migration_jobs
    # table.
    expect(table(:background_migration_jobs).count).to eq(2)
    expect(table(:background_migration_jobs).first.arguments).to eq([projects[0].id, projects[2].id])
    expect(table(:background_migration_jobs).second.arguments).to eq([projects[3].id, projects[3].id])

    expect(described_class::MIGRATION)
      .to be_scheduled_delayed_migration(2.minutes, projects[0].id, projects[2].id)

    expect(described_class::MIGRATION)
      .to be_scheduled_delayed_migration(4.minutes, projects[3].id, projects[3].id)
  end

  it 'schedules jobs according to the configured batch size' do
    expect { migrate! }.to change { BackgroundMigrationWorker.jobs.size }.by(2)
  end
end
