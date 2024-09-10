# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMlCandidateParamsProjectId,
  feature_category: :mlops,
  schema: 20240906131411 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :ml_candidate_params }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :ml_candidates }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :candidate_id }
  end
end
