# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPackagesDebianFileMetadataProjectId,
  feature_category: :package_registry,
  schema: 20250320085929 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :packages_debian_file_metadata }
    let(:backfill_column) { :project_id }
    let(:batch_column) { :package_file_id }
    let(:backfill_via_table) { :packages_package_files }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :package_file_id }
  end
end
