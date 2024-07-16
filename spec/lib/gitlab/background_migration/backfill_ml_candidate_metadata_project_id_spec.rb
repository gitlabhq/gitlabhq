# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMlCandidateMetadataProjectId,
  feature_category: :mlops,
  schema: 20240626142202 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :ml_candidate_metadata }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :ml_candidates }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :candidate_id }
  end
end
