# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCiBuildsRunnerSessionProjectId,
  feature_category: :runner,
  schema: 20240930144640,
  migration: :gitlab_ci do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :ci_builds_runner_session }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :p_ci_builds }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :build_id }
  end
end
