# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeFixGitlabSubscriptionHistoriesHostedPlanNameUid, migration: :gitlab_main_org,
  feature_category: :subscription_management do
  it 'finalizes the batched background migration' do
    expect(described_class).to ensure_batched_background_migration_is_finished_for(
      job_class_name: 'FixGitlabSubscriptionHistoriesHostedPlanNameUid',
      table_name: :gitlab_subscription_histories,
      column_name: :id,
      job_arguments: [],
      finalize: true,
      skip_early_finalization_validation: true
    )

    migrate!
  end
end
