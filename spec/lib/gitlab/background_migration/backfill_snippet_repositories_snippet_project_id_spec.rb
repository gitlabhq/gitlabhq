# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillSnippetRepositoriesSnippetProjectId,
  feature_category: :source_code_management,
  schema: 20241211134706 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :snippet_repositories }
    let(:backfill_column) { :snippet_project_id }
    let(:batch_column) { :snippet_id }
    let(:backfill_via_table) { :snippets }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :snippet_id }
  end
end
