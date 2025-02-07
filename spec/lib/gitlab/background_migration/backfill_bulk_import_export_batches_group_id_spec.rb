# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillBulkImportExportBatchesGroupId,
  feature_category: :importers,
  schema: 20250205194216 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :bulk_import_export_batches }
    let(:backfill_column) { :group_id }
    let(:backfill_via_table) { :bulk_import_exports }
    let(:backfill_via_column) { :group_id }
    let(:backfill_via_foreign_key) { :export_id }
  end
end
