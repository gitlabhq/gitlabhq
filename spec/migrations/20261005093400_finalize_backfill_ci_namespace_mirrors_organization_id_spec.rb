# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeBackfillCiNamespaceMirrorsOrganizationId, migration: :gitlab_ci,
  feature_category: :continuous_integration do
  it 'finalizes the batched background migration' do
    expect(described_class).to ensure_batched_background_migration_is_finished_for(
      job_class_name: 'BackfillCiNamespaceMirrorsOrganizationId',
      table_name: :ci_namespace_mirrors,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )

    migrate!
  end
end
