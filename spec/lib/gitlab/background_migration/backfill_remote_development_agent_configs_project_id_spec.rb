# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillRemoteDevelopmentAgentConfigsProjectId,
  feature_category: :workspaces,
  schema: 20240530122155 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :remote_development_agent_configs }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :cluster_agents }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :cluster_agent_id }
  end
end
