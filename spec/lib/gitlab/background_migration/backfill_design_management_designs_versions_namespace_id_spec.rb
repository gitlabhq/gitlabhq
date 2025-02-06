# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDesignManagementDesignsVersionsNamespaceId,
  feature_category: :design_management,
  schema: 20250204151104 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :design_management_designs_versions }
    let(:backfill_column) { :namespace_id }
    let(:backfill_via_table) { :design_management_designs }
    let(:backfill_via_column) { :namespace_id }
    let(:backfill_via_foreign_key) { :design_id }
  end
end
