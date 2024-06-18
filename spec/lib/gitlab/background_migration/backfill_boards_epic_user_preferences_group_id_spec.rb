# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillBoardsEpicUserPreferencesGroupId,
  feature_category: :portfolio_management,
  schema: 20240521094913 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :boards_epic_user_preferences }
    let(:backfill_column) { :group_id }
    let(:backfill_via_table) { :epics }
    let(:backfill_via_column) { :group_id }
    let(:backfill_via_foreign_key) { :epic_id }
  end
end
