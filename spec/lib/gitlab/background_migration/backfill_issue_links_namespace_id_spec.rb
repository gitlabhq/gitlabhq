# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillIssueLinksNamespaceId,
  feature_category: :team_planning,
  schema: 20240613073927 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :issue_links }
    let(:backfill_column) { :namespace_id }
    let(:backfill_via_table) { :issues }
    let(:backfill_via_column) { :namespace_id }
    let(:backfill_via_foreign_key) { :source_id }
  end
end
