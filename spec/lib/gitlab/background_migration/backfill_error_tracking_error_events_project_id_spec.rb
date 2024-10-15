# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillErrorTrackingErrorEventsProjectId,
  feature_category: :observability,
  schema: 20240731160140 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :error_tracking_error_events }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :error_tracking_errors }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :error_id }
  end
end
