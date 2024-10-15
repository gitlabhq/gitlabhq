# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDastSiteProfilesBuildsProjectId,
  feature_category: :dynamic_application_security_testing,
  schema: 20241001122042,
  migration: :gitlab_sec do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :dast_site_profiles_builds }
    let(:batch_column) { :ci_build_id }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :dast_site_profiles }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :dast_site_profile_id }
  end
end
