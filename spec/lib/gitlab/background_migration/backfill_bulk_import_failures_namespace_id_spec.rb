# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillBulkImportFailuresNamespaceId,
  feature_category: :importers,
  schema: 20250205194752 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :bulk_import_failures }
    let(:backfill_column) { :namespace_id }
    let(:backfill_via_table) { :bulk_import_entities }
    let(:backfill_via_column) { :namespace_id }
    let(:backfill_via_foreign_key) { :bulk_import_entity_id }
  end
end
