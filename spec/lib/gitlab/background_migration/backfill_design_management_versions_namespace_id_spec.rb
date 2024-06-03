# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDesignManagementVersionsNamespaceId,
  feature_category: :design_management,
  schema: 20240530121652 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :design_management_versions }
    let(:backfill_column) { :namespace_id }
    let(:backfill_via_table) { :issues }
    let(:backfill_via_column) { :namespace_id }
    let(:backfill_via_foreign_key) { :issue_id }
  end
end
