# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillWikiPageSlugsNamespaceId,
  feature_category: :wiki,
  schema: 20250304103242 do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :wiki_page_slugs }
    let(:backfill_column) { :namespace_id }
    let(:backfill_via_table) { :wiki_page_meta }
    let(:backfill_via_column) { :namespace_id }
    let(:backfill_via_foreign_key) { :wiki_page_meta_id }
  end
end
