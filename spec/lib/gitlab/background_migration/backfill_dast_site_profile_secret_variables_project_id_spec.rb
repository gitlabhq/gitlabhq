# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDastSiteProfileSecretVariablesProjectId,
  feature_category: :dynamic_application_security_testing,
  schema: 20240605192707 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :dast_site_profile_secret_variables }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :dast_site_profiles }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :dast_site_profile_id }
  end
end
