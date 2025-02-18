# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillOperationsScopesProjectId,
  feature_category: :feature_flags,
  schema: 20250204151544 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :operations_scopes }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :operations_strategies }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :strategy_id }
  end
end
