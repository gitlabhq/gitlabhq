# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe StartBackfillCiQueuingTables, :suppress_gitlab_schemas_validate_connection,
  feature_category: :continuous_integration do
  let(:namespaces) { table(:namespaces) }
  let(:projects)   { table(:projects) }
  let(:builds)     { table(:ci_builds) }

  let!(:namespace) do
    namespaces.create!(name: 'namespace1', path: 'namespace1')
  end

  let!(:project) do
    projects.create!(namespace_id: namespace.id, name: 'test1', path: 'test1')
  end

  let!(:pending_build_1) do
    builds.create!(status: :pending, name: 'test1', type: 'Ci::Build', project_id: project.id)
  end

  let!(:running_build) do
    builds.create!(status: :running, name: 'test2', type: 'Ci::Build', project_id: project.id)
  end

  let!(:pending_build_2) do
    builds.create!(status: :pending, name: 'test3', type: 'Ci::Build', project_id: project.id)
  end

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 1)
  end

  it 'schedules jobs for builds that are pending' do
    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(
          2.minutes, pending_build_1.id, pending_build_1.id)
        expect(described_class::MIGRATION).to be_scheduled_delayed_migration(
          4.minutes, pending_build_2.id, pending_build_2.id)
        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end
end
