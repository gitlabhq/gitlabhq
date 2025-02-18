# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDesignManagementRepositoryStatesNamespaceId,
  feature_category: :geo_replication,
  schema: 20250205193111 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :design_management_repository_states }
    let(:backfill_column) { :namespace_id }
    let(:batch_column) { :design_management_repository_id }
    let(:backfill_via_table) { :design_management_repositories }
    let(:backfill_via_column) { :namespace_id }
    let(:backfill_via_foreign_key) { :design_management_repository_id }
  end
end
