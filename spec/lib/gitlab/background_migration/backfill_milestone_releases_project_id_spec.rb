# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillMilestoneReleasesProjectId,
  feature_category: :release_orchestration,
  schema: 20240918111134 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :milestone_releases }
    let(:batch_column) { :milestone_id }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :releases }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :release_id }
  end
end
