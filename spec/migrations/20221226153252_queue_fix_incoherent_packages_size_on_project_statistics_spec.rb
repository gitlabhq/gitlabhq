# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueFixIncoherentPackagesSizeOnProjectStatistics, feature_category: :package_registry do
  let(:batched_migration) { described_class::MIGRATION }

  context 'with no packages' do
    it 'does not schedule a new batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }
      end
    end
  end

  context 'with some packages' do
    before do
      namespace = table(:namespaces)
                    .create!(name: 'project', path: 'project', type: 'Project')
      project = table(:projects).create!(
        name: 'project',
        path: 'project',
        project_namespace_id: namespace.id,
        namespace_id: namespace.id
      )
      table(:packages_packages)
        .create!(name: 'test', version: '1.2.3', package_type: 2, project_id: project.id)
    end

    it 'schedules a new batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).to have_scheduled_batched_migration(
            table_name: :project_statistics,
            column_name: :id,
            interval: described_class::DELAY_INTERVAL,
            batch_size: described_class::BATCH_SIZE
          )
        }
      end
    end
  end
end
