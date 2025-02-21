# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPackagesDebianGroupComponentFilesGroupId,
  feature_category: :package_registry,
  schema: 20250220131530 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :packages_debian_group_component_files }
    let(:backfill_column) { :group_id }
    let(:backfill_via_table) { :packages_debian_group_components }
    let(:backfill_via_column) { :group_id }
    let(:backfill_via_foreign_key) { :component_id }
  end
end
