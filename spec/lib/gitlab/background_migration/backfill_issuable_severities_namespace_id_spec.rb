# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillIssuableSeveritiesNamespaceId,
  feature_category: :team_planning,
  schema: 20241125145005 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :issuable_severities }
    let(:backfill_column) { :namespace_id }
    let(:backfill_via_table) { :issues }
    let(:backfill_via_column) { :namespace_id }
    let(:backfill_via_foreign_key) { :issue_id }
  end
end
