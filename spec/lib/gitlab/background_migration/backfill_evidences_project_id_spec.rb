# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillEvidencesProjectId,
  feature_category: :release_evidence,
  schema: 20240716133948 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :evidences }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :releases }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :release_id }
  end
end
