# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillRelatedEpicLinksGroupId,
  feature_category: :portfolio_management,
  schema: 20240613065416 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :related_epic_links }
    let(:backfill_column) { :group_id }
    let(:backfill_via_table) { :epics }
    let(:backfill_via_column) { :group_id }
    let(:backfill_via_foreign_key) { :source_id }
  end
end
