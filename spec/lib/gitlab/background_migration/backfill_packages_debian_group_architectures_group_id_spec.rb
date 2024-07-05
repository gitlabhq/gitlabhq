# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPackagesDebianGroupArchitecturesGroupId,
  feature_category: :package_registry,
  schema: 20240702072515 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :packages_debian_group_architectures }
    let(:backfill_column) { :group_id }
    let(:backfill_via_table) { :packages_debian_group_distributions }
    let(:backfill_via_column) { :group_id }
    let(:backfill_via_foreign_key) { :distribution_id }
  end
end
