# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPackagesDebianProjectComponentFilesProjectId,
  feature_category: :package_registry,
  schema: 20250307100237 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :packages_debian_project_component_files }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :packages_debian_project_components }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :component_id }
  end
end
