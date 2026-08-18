# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeHkDeleteNullProjectIdPushRules, migration: :gitlab_main_org, feature_category: :source_code_management do
  it 'is a no-op' do
    expect(described_class).not_to ensure_batched_background_migration_is_finished_for(
      job_class_name: 'DeleteNullProjectIdPushRules',
      table_name: :push_rules,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )

    migrate!
  end
end
