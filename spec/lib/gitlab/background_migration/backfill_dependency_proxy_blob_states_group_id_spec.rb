# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDependencyProxyBlobStatesGroupId,
  feature_category: :geo_replication,
  schema: 20241015075953 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :dependency_proxy_blob_states }
    let(:backfill_column) { :group_id }
    let(:batch_column) { :dependency_proxy_blob_id }
    let(:backfill_via_table) { :dependency_proxy_blobs }
    let(:backfill_via_column) { :group_id }
    let(:backfill_via_foreign_key) { :dependency_proxy_blob_id }
  end
end
