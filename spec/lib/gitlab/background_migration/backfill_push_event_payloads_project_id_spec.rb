# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPushEventPayloadsProjectId,
  feature_category: :source_code_management do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :push_event_payloads }
    let(:backfill_column) { :project_id }
    let(:batch_column) { :event_id }
    let(:backfill_via_table) { :events }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :event_id }
  end
end
