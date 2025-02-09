# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillBulkImportTrackersProjectId,
  feature_category: :importers,
  schema: 20250205195328 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :bulk_import_trackers }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :bulk_import_entities }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :bulk_import_entity_id }
  end
end
