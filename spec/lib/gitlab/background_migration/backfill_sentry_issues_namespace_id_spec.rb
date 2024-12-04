# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillSentryIssuesNamespaceId,
  feature_category: :observability,
  schema: 20241203144833 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :sentry_issues }
    let(:backfill_column) { :namespace_id }
    let(:backfill_via_table) { :issues }
    let(:backfill_via_column) { :namespace_id }
    let(:backfill_via_foreign_key) { :issue_id }
  end
end
