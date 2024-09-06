# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillWorkspaceVariablesProjectId,
  feature_category: :workspaces,
  schema: 20240419035356 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :workspace_variables }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :workspaces }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :workspace_id }
  end
end
