# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillBulkImportConfigurationsOrganizationId,
  feature_category: :importers,
  schema: 20250408122856 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :bulk_import_configurations }
    let(:backfill_column) { :organization_id }
    let(:backfill_via_table) { :bulk_imports }
    let(:backfill_via_column) { :organization_id }
    let(:backfill_via_foreign_key) { :bulk_import_id }
  end
end
