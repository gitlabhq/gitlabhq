# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillEpicUserMentionsGroupId,
  feature_category: :team_planning,
  schema: 20240612071559 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :epic_user_mentions }
    let(:backfill_column) { :group_id }
    let(:backfill_via_table) { :epics }
    let(:backfill_via_column) { :group_id }
    let(:backfill_via_foreign_key) { :epic_id }
  end
end
