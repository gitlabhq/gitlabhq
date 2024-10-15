# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPagesDeploymentStatesProjectId,
  feature_category: :pages,
  schema: 20240930123052 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :pages_deployment_states }
    let(:batch_column) { :pages_deployment_id }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :pages_deployments }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :pages_deployment_id }
  end
end
