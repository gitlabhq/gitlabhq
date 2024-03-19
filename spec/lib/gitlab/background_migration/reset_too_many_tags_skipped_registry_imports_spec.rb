# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::ResetTooManyTagsSkippedRegistryImports, :migration,
  :aggregate_failures,
  schema: 20230616082958 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:container_repositories) { table(:container_repositories) }

  subject(:background_migration) { described_class.new }

  let!(:namespace) { namespaces.create!(id: 1, path: 'foo', name: 'foo') }
  let!(:project) { projects.create!(id: 1, project_namespace_id: 1, namespace_id: 1, path: 'bar', name: 'bar') }

  let!(:container_repository1) do
    container_repositories.create!(
      id: 1,
      project_id: 1,
      name: 'a',
      migration_state: 'import_skipped',
      migration_skipped_at: Time.zone.now,
      migration_skipped_reason: 2,
      migration_pre_import_started_at: Time.zone.now,
      migration_pre_import_done_at: Time.zone.now,
      migration_import_started_at: Time.zone.now,
      migration_import_done_at: Time.zone.now,
      migration_aborted_at: Time.zone.now,
      migration_retries_count: 2,
      migration_aborted_in_state: 'importing'
    )
  end

  let!(:container_repository2) do
    container_repositories.create!(
      id: 2,
      project_id: 1,
      name: 'b',
      migration_state: 'import_skipped',
      migration_skipped_at: Time.zone.now,
      migration_skipped_reason: 2
    )
  end

  let!(:container_repository3) do
    container_repositories.create!(
      id: 3,
      project_id: 1,
      name: 'c',
      migration_state: 'import_skipped',
      migration_skipped_at: Time.zone.now,
      migration_skipped_reason: 1
    )
  end

  # This is an unlikely state, but included here to test the edge case
  let!(:container_repository4) do
    container_repositories.create!(
      id: 4,
      project_id: 1,
      name: 'd',
      migration_state: 'default',
      migration_skipped_reason: 2
    )
  end

  describe '#up' do
    it 'resets only qualified container repositories', :aggregate_failures do
      background_migration.perform(1, 4)

      expect(container_repository1.reload.migration_state).to eq('default')
      expect(container_repository1.migration_skipped_reason).to eq(nil)
      expect(container_repository1.migration_pre_import_started_at).to eq(nil)
      expect(container_repository1.migration_pre_import_done_at).to eq(nil)
      expect(container_repository1.migration_import_started_at).to eq(nil)
      expect(container_repository1.migration_import_done_at).to eq(nil)
      expect(container_repository1.migration_aborted_at).to eq(nil)
      expect(container_repository1.migration_skipped_at).to eq(nil)
      expect(container_repository1.migration_retries_count).to eq(0)
      expect(container_repository1.migration_aborted_in_state).to eq(nil)

      expect(container_repository2.reload.migration_state).to eq('default')
      expect(container_repository2.migration_skipped_reason).to eq(nil)

      expect(container_repository3.reload.migration_state).to eq('import_skipped')
      expect(container_repository3.migration_skipped_reason).to eq(1)

      expect(container_repository4.reload.migration_state).to eq('default')
      expect(container_repository4.migration_skipped_reason).to eq(2)
    end
  end
end
