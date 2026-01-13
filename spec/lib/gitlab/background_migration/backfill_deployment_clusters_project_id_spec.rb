# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDeploymentClustersProjectId,
  feature_category: :deployment_management do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :deployment_clusters }
    let(:batch_column) { :deployment_id }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :deployments }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :deployment_id }
  end
end
