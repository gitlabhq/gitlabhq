# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeCleanupSecurityPolicyBotUsers, migration: :gitlab_main, feature_category: :security_policy_management do
  it 'finalizes the batched background migration' do
    expect(described_class).to ensure_batched_background_migration_is_finished_for(
      job_class_name: 'CleanupSecurityPolicyBotUsers',
      table_name: :users,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )

    migrate!
  end
end
