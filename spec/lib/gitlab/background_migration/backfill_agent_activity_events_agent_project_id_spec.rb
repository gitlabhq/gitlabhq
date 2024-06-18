# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillAgentActivityEventsAgentProjectId,
  feature_category: :deployment_management,
  schema: 20240529184612 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :agent_activity_events }
    let(:backfill_column) { :agent_project_id }
    let(:backfill_via_table) { :cluster_agents }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :agent_id }
  end
end
