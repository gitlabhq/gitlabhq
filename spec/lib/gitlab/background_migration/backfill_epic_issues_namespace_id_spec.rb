# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillEpicIssuesNamespaceId,
  feature_category: :portfolio_management,
  schema: 20240618123925 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :epic_issues }
    let(:backfill_column) { :namespace_id }
    let(:backfill_via_table) { :issues }
    let(:backfill_via_column) { :namespace_id }
    let(:backfill_via_foreign_key) { :issue_id }
  end
end
