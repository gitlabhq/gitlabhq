# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPackagesPackageFileStatesProjectId,
  feature_category: :geo_replication,
  schema: 20260227005512,
  migration: :gitlab_main_org do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :packages_package_file_states }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :packages_package_files }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :package_file_id }
  end
end
