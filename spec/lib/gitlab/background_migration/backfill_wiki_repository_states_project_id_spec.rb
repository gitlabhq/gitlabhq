# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillWikiRepositoryStatesProjectId,
  feature_category: :geo_replication,
  schema: 20240419035616 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :wiki_repository_states }
    let(:backfill_column) { :project_id }
    let(:backfill_via_table) { :project_wiki_repositories }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :project_wiki_repository_id }
  end
end
