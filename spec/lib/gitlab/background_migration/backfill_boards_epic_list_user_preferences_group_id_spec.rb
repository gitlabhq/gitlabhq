# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillBoardsEpicListUserPreferencesGroupId,
  feature_category: :portfolio_management,
  schema: 20250203151631 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :boards_epic_list_user_preferences }
    let(:backfill_column) { :group_id }
    let(:backfill_via_table) { :boards_epic_lists }
    let(:backfill_via_column) { :group_id }
    let(:backfill_via_foreign_key) { :epic_list_id }
  end
end
