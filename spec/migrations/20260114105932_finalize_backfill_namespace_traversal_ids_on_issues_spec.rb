# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeBackfillNamespaceTraversalIdsOnIssues,
  migration: :gitlab_main_org,
  feature_category: :portfolio_management do
  it 'finalizes the batched migration' do
    expect(described_class).to ensure_batched_background_migration_is_finished_for(
      job_class_name: described_class::MIGRATION,
      table_name: :issues,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )

    migrate!
  end
end
