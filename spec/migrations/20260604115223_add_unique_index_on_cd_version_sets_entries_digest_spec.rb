# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddUniqueIndexOnCdVersionSetsEntriesDigest, migration: :gitlab_main,
  feature_category: :continuous_delivery do
  let(:index_name) { described_class::INDEX_NAME }
  let(:connection) { described_class.new.connection }

  it 'adds the unique index' do
    migrate!

    expect(connection.index_exists?(:cd_version_sets, nil, name: index_name)).to be(true)
  end

  it 'removes the unique index on rollback' do
    migrate!
    schema_migrate_down!

    expect(connection.index_exists?(:cd_version_sets, nil, name: index_name)).to be(false)
  end
end
