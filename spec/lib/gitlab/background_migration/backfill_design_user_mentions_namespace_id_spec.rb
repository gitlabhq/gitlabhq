# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDesignUserMentionsNamespaceId,
  feature_category: :team_planning,
  schema: 20250209005142 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :design_user_mentions }
    let(:backfill_column) { :namespace_id }
    let(:backfill_via_table) { :design_management_designs }
    let(:backfill_via_column) { :namespace_id }
    let(:backfill_via_foreign_key) { :design_id }
  end
end
