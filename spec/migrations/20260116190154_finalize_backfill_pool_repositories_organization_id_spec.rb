# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeBackfillPoolRepositoriesOrganizationId, migration: :gitlab_main_org, feature_category: :source_code_management do
  it 'finalizes the batched background migration' do
    expect(described_class).to ensure_batched_background_migration_is_finished_for(
      job_class_name: 'BackfillPoolRepositoriesOrganizationId',
      table_name: :pool_repositories,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )

    migrate!
  end
end
