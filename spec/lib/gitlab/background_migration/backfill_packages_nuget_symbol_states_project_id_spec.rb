# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPackagesNugetSymbolStatesProjectId,
  feature_category: :geo_replication do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :packages_nuget_symbol_states }
    let(:backfill_column) { :project_id }
    let(:batch_column) { :packages_nuget_symbol_id }
    let(:backfill_via_table) { :packages_nuget_symbols }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :packages_nuget_symbol_id }
  end
end
