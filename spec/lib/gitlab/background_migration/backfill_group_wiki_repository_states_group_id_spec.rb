# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillGroupWikiRepositoryStatesGroupId,
  feature_category: :geo_replication,
  schema: 20241125133011 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :group_wiki_repository_states }
    let(:backfill_column) { :group_id }
    let(:backfill_via_table) { :group_wiki_repositories }
    let(:backfill_via_column) { :group_id }
    let(:backfill_via_foreign_key) { :group_wiki_repository_id }
  end
end
