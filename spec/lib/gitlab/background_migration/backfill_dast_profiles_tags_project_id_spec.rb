# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDastProfilesTagsProjectId,
  feature_category: :dynamic_application_security_testing,
  schema: 20240604145219 do
  before(:all) do
    # This migration will not work if a sec database is configured. It should be finalized and removed prior to
    # sec db rollout.
    # Consult https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171707 for more info.
    skip_if_multiple_databases_are_setup(:sec)
  end

  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :dast_profiles_tags }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :dast_profiles }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :dast_profile_id }
  end
end
