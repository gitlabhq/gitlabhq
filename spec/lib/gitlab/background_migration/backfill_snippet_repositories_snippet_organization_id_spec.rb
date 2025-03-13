# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillSnippetRepositoriesSnippetOrganizationId,
  feature_category: :source_code_management,
  schema: 20241211134711 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :snippet_repositories }
    let(:backfill_column) { :snippet_organization_id }
    let(:batch_column) { :snippet_id }
    let(:backfill_via_table) { :snippets }
    let(:backfill_via_column) { :organization_id }
    let(:backfill_via_foreign_key) { :snippet_id }
  end
end
