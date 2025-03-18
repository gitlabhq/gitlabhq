# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPackagesNugetDependencyLinkMetadataProjectId,
  feature_category: :package_registry,
  schema: 20250314120526 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :packages_nuget_dependency_link_metadata }
    let(:backfill_column) { :project_id }
    let(:batch_column) { :dependency_link_id }
    let(:backfill_via_table) { :packages_dependency_links }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :dependency_link_id }
  end
end
