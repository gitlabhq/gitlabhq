# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillTerraformStateVersionsProjectId,
  feature_category: :infrastructure_as_code,
  schema: 20240605132806 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :terraform_state_versions }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :terraform_states }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :terraform_state_id }
  end
end
