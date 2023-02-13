# frozen_string_literal: true

require 'spec_helper'
require 'rake_helper'
require_migration!

RSpec.describe AddProjectsEmailsEnabledColumnData, :migration, feature_category: :database do
  before :all do
    Rake.application.rake_require 'active_record/railties/databases'
    Rake.application.rake_require 'tasks/gitlab/db'

    # empty task as env is already loaded
    Rake::Task.define_task :environment
  end

  let(:migration) { described_class::MIGRATION }
  let(:project_settings) { table(:project_settings) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }

  before do
    stub_const("#{described_class.name}::SUB_BATCH_SIZE", 2)
  end

  it 'schedules background migrations', :aggregate_failures do
    migrate!

    expect(migration).to have_scheduled_batched_migration(
      table_name: :projects,
      column_name: :id,
      interval: described_class::DELAY_INTERVAL
    )
  end

  describe '#down' do
    it 'deletes all batched migration records' do
      migrate!
      schema_migrate_down!

      expect(migration).not_to have_scheduled_batched_migration
    end
  end

  it 'sets emails_enabled to be the opposite of emails_disabled' do
    disabled_records_to_migrate = 4
    enabled_records_to_migrate  = 2

    disabled_records_to_migrate.times do |i|
      namespace = namespaces.create!(name: 'namespace', path: "namespace#{i}")
      project = projects.create!(name: "Project Disabled #{i}",
        path: "projectDisabled#{i}",
        namespace_id: namespace.id,
        project_namespace_id: namespace.id,
        emails_disabled: true)
      project_settings.create!(project_id: project.id)
    end

    enabled_records_to_migrate.times do |i|
      namespace = namespaces.create!(name: 'namespace', path: "namespace#{i}")
      project = projects.create!(name: "Project Enabled #{i}",
        path: "projectEnabled#{i}",
        namespace_id: namespace.id,
        project_namespace_id: namespace.id,
        emails_disabled: false)
      project_settings.create!(project_id: project.id)
    end

    migrate!
    run_rake_task('gitlab:db:execute_batched_migrations')
    # rubocop: disable CodeReuse/ActiveRecord
    expect(project_settings.where(emails_enabled: true).count).to eq(enabled_records_to_migrate)
    expect(project_settings.where(emails_enabled: false).count).to eq(disabled_records_to_migrate)
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
