# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillBulkImportExportUploadsGroupId,
  feature_category: :importers,
  schema: 20241213150050 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :bulk_import_export_uploads }
    let(:backfill_column) { :group_id }
    let(:backfill_via_table) { :bulk_import_exports }
    let(:backfill_via_column) { :group_id }
    let(:backfill_via_foreign_key) { :export_id }
  end
end
