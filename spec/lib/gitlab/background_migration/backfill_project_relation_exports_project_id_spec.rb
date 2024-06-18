# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillProjectRelationExportsProjectId,
  feature_category: :importers,
  schema: 20240605113246 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :project_relation_exports }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :project_export_jobs }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :project_export_job_id }
  end
end
