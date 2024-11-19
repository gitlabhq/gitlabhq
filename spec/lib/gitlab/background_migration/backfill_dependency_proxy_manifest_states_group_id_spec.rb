# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDependencyProxyManifestStatesGroupId,
  feature_category: :geo_replication,
  schema: 20241015080743 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :dependency_proxy_manifest_states }
    let(:backfill_column) { :group_id }
    let(:batch_column) { :dependency_proxy_manifest_id }
    let(:backfill_via_table) { :dependency_proxy_manifests }
    let(:backfill_via_column) { :group_id }
    let(:backfill_via_foreign_key) { :dependency_proxy_manifest_id }
  end
end
