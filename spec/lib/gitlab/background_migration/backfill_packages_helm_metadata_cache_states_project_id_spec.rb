# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPackagesHelmMetadataCacheStatesProjectId,
  feature_category: :geo_replication do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :packages_helm_metadata_cache_states }
    let(:backfill_column) { :project_id }
    let(:batch_column) { :id }
    let(:backfill_via_table) { :packages_helm_metadata_caches }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :packages_helm_metadata_cache_id }
  end
end
