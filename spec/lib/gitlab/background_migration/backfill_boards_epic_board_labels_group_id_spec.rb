# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillBoardsEpicBoardLabelsGroupId,
  feature_category: :portfolio_management,
  schema: 20240521090842 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :boards_epic_board_labels }
    let(:backfill_column) { :group_id }
    let(:backfill_via_table) { :boards_epic_boards }
    let(:backfill_via_column) { :group_id }
    let(:backfill_via_foreign_key) { :epic_board_id }
  end
end
