# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillSnippetRepositoryStatesSnippetProjectId,
  feature_category: :geo_replication,
  schema: 20260223183042 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :snippet_repository_states }
    let(:backfill_column) { :snippet_project_id }
    let(:backfill_via_table) { :snippet_repositories }
    let(:backfill_via_column) { :snippet_project_id }
    let(:backfill_via_foreign_key) { :snippet_repository_id }
    let(:backfill_via_table_primary_key) { :snippet_id }
  end
end
