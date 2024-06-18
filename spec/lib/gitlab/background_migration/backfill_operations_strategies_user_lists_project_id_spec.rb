# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillOperationsStrategiesUserListsProjectId,
  feature_category: :feature_flags,
  schema: 20240612073055 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :operations_strategies_user_lists }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :operations_user_lists }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :user_list_id }
  end
end
