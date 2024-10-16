# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillContainerRepositoryStatesProjectId,
  feature_category: :geo_replication,
  schema: 20241015082357 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :container_repository_states }
    let(:batch_column) { :container_repository_id }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :container_repositories }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :container_repository_id }
  end
end
