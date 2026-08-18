# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddTemporaryProgrammingLanguageIdIndexToRepositoryLanguages,
  migration: :gitlab_main_org, feature_category: :source_code_management do
  let(:connection) { described_class.new.connection }
  let(:index_name) { described_class::INDEX_NAME }

  it 'creates the index' do
    migrate!

    expect(connection.indexes(:repository_languages).map(&:name)).to include(index_name)
  end

  it 'removes the index on rollback' do
    migrate!
    schema_migrate_down!

    expect(connection.indexes(:repository_languages).map(&:name)).not_to include(index_name)
  end
end
