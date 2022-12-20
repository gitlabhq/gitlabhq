# frozen_string_literal: true

require 'spec_helper'
require_migration!('finalize_traversal_ids_background_migrations')

RSpec.describe FinalizeTraversalIdsBackgroundMigrations, :migration, feature_category: :database do
  shared_context 'incomplete background migration' do
    before do
      # Jobs enqueued in Sidekiq.
      Sidekiq::Testing.disable! do
        BackgroundMigrationWorker.perform_in(10, job_class_name, [1, 2, 100])
        BackgroundMigrationWorker.perform_in(20, job_class_name, [3, 4, 100])
      end

      # Jobs tracked in the database.
      # table(:background_migration_jobs).create!(
      Gitlab::Database::BackgroundMigrationJob.create!(
        class_name: job_class_name,
        arguments: [5, 6, 100],
        status: Gitlab::Database::BackgroundMigrationJob.statuses['pending']
      )
      # table(:background_migration_jobs).create!(
      Gitlab::Database::BackgroundMigrationJob.create!(
        class_name: job_class_name,
        arguments: [7, 8, 100],
        status: Gitlab::Database::BackgroundMigrationJob.statuses['succeeded']
      )
    end
  end

  context 'BackfillNamespaceTraversalIdsRoots background migration' do
    let(:job_class_name) { 'BackfillNamespaceTraversalIdsRoots' }

    include_context 'incomplete background migration'

    before do
      migrate!
    end

    it_behaves_like(
      'finalized tracked background migration',
      Gitlab::BackgroundMigration::BackfillNamespaceTraversalIdsRoots
    )
  end

  context 'BackfillNamespaceTraversalIdsChildren background migration' do
    let(:job_class_name) { 'BackfillNamespaceTraversalIdsChildren' }

    include_context 'incomplete background migration'

    before do
      migrate!
    end

    it_behaves_like(
      'finalized tracked background migration',
      Gitlab::BackgroundMigration::BackfillNamespaceTraversalIdsChildren
    )
  end
end
