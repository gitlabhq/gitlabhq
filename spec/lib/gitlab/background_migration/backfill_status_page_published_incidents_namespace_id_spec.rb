# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillStatusPagePublishedIncidentsNamespaceId,
  feature_category: :incident_management,
  schema: 20241205143056 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :status_page_published_incidents }
    let(:backfill_column) { :namespace_id }
    let(:backfill_via_table) { :issues }
    let(:backfill_via_column) { :namespace_id }
    let(:backfill_via_foreign_key) { :issue_id }
  end
end
