# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPackagesDebianPublicationsProjectId,
  feature_category: :package_registry,
  schema: 20240610140901 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :packages_debian_publications }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :packages_packages }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :package_id }
  end
end
