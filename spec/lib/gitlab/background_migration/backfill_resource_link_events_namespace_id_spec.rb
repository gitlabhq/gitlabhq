# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillResourceLinkEventsNamespaceId,
  feature_category: :team_planning,
  schema: 20241202141407 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :resource_link_events }
    let(:backfill_column) { :namespace_id }
    let(:backfill_via_table) { :issues }
    let(:backfill_via_column) { :namespace_id }
    let(:backfill_via_foreign_key) { :issue_id }
  end
end
