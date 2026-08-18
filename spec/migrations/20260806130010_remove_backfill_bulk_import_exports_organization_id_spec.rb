# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveBackfillBulkImportExportsOrganizationId, migration: :gitlab_main_org, feature_category: :importers do
  let!(:batched_migration) do
    Gitlab::Database::BackgroundMigration::BatchedMigration.create!(
      job_class_name: 'BackfillBulkImportExportsOrganizationId',
      table_name: :bulk_import_exports,
      column_name: :id,
      job_arguments: [],
      interval: 120,
      min_value: 1,
      max_value: 2,
      batch_size: 1000,
      sub_batch_size: 100,
      gitlab_schema: :gitlab_main_org
    )
  end

  it 'removes the batched background migration' do
    expect { migrate! }.to change {
      Gitlab::Database::BackgroundMigration::BatchedMigration.where(id: batched_migration.id).exists?
    }.from(true).to(false)
  end
end
