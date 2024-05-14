# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillWorkItemParentLinksNamespaceId,
  feature_category: :team_planning,
  schema: 20240419035504 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :work_item_parent_links }
    let(:backfill_column) { :namespace_id }
    let(:backfill_via_table) { :issues }
    let(:backfill_via_column) { :namespace_id }
    let(:backfill_via_foreign_key) { :work_item_id }
  end
end
