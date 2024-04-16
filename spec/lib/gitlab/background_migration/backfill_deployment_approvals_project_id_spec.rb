# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDeploymentApprovalsProjectId,
  feature_category: :continuous_delivery,
  schema: 20240410004333 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :deployment_approvals }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :deployments }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :deployment_id }
  end
end
