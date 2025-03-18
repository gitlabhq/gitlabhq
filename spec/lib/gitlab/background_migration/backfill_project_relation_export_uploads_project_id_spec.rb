# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillProjectRelationExportUploadsProjectId,
  feature_category: :importers,
  schema: 20250220130527 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :project_relation_export_uploads }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :project_relation_exports }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :project_relation_export_id }
  end
end
