# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupBackfillIntegrationsEnableSslVerification, :migration,
  feature_category: :system_access do
  let(:job_class_name) { 'BackfillIntegrationsEnableSslVerification' }

  before do
    # Jobs enqueued in Sidekiq.
    Sidekiq::Testing.disable! do
      BackgroundMigrationWorker.perform_in(10, job_class_name, [1, 2])
      BackgroundMigrationWorker.perform_in(20, job_class_name, [3, 4])
    end

    # Jobs tracked in the database.
    Gitlab::Database::BackgroundMigrationJob.create!(
      class_name: job_class_name,
      arguments: [5, 6],
      status: Gitlab::Database::BackgroundMigrationJob.statuses['pending']
    )
    Gitlab::Database::BackgroundMigrationJob.create!(
      class_name: job_class_name,
      arguments: [7, 8],
      status: Gitlab::Database::BackgroundMigrationJob.statuses['succeeded']
    )

    migrate!
  end

  it_behaves_like(
    'finalized tracked background migration',
    Gitlab::BackgroundMigration::BackfillIntegrationsEnableSslVerification
  )
end
