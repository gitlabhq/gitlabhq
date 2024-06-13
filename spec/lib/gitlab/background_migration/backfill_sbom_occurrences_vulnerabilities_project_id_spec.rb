# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillSbomOccurrencesVulnerabilitiesProjectId,
  feature_category: :dependency_management,
  schema: 20240612075301 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :sbom_occurrences_vulnerabilities }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :sbom_occurrences }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :sbom_occurrence_id }
  end
end
