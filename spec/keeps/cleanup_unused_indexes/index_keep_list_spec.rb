# frozen_string_literal: true

require 'spec_helper'
require './keeps/helpers/index_keep_list'

RSpec.describe 'keeps/cleanup_unused_indexes/index_keep_list.yml', feature_category: :database do
  let(:yaml_path) { Rails.root.join('keeps/cleanup_unused_indexes/index_keep_list.yml') }

  subject(:keep_list) { Keeps::Helpers::IndexKeepList.new(yaml_path: yaml_path) }

  it 'parses and every entry has the required keys' do
    expect { keep_list.entries }.not_to raise_error
  end

  it 'references only indexes that actually exist in the test database' do
    existing_identifiers = Gitlab::Database::PostgresIndex.pluck(:identifier).to_set

    stale = keep_list.entries.keys.reject { |id| existing_identifiers.include?(id) }
    message = "keeps/cleanup_unused_indexes/index_keep_list.yml references indexes " \
      "that do not exist in gitlabhq_test: #{stale.join(', ')}"
    expect(stale).to be_empty, message
  end

  it 'detects entries that reference indexes missing from the test database' do
    bogus_id = 'public.this_index_does_not_exist_in_test_db_xyz123'
    allow(keep_list).to receive(:entries).and_return(bogus_id => {})

    existing_identifiers = Gitlab::Database::PostgresIndex.pluck(:identifier).to_set
    stale = keep_list.entries.keys.reject { |id| existing_identifiers.include?(id) }

    expect(stale).to contain_exactly(bogus_id)
  end
end
