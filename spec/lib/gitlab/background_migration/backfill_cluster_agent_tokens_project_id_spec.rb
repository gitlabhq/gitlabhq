# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillClusterAgentTokensProjectId,
  feature_category: :deployment_management,
  schema: 20240216020102 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :cluster_agent_tokens }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :cluster_agents }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :agent_id }
  end
end
