# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPackagesDebianProjectArchitecturesProjectId,
  feature_category: :package_registry,
  schema: 20240628133954 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :packages_debian_project_architectures }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :packages_debian_project_distributions }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :distribution_id }
  end
end
