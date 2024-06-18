# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillBoardsEpicListsGroupId,
  feature_category: :portfolio_management,
  schema: 20240521093520 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :boards_epic_lists }
    let(:backfill_column) { :group_id }
    let(:backfill_via_table) { :boards_epic_boards }
    let(:backfill_via_column) { :group_id }
    let(:backfill_via_foreign_key) { :epic_board_id }
  end
end
