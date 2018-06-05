require 'spec_helper'

describe Gitlab::BackgroundMigration::RebuildTrigramIndex, :migration, schema: 20180608201435, if: Gitlab::Database.postgresql? do
  subject { migration.perform(table, column) }
  let(:table) { "issues" }
  let(:column) { "description" }
  let(:migration) { described_class.new }

  let(:index_name) { "index_#{table}_on_#{column}_trigram" }
  let(:index_name_old) { "#{index_name}_old" }

  it 'renames the existing index' do
    expect(migration).to receive(:rename_index).with(table, index_name, index_name_old).and_call_original

    subject
  end

  it 'creates a new index' do
    allow(migration).to receive(:execute)

    expect(migration).to receive(:execute).with("CREATE INDEX CONCURRENTLY #{index_name} ON #{table} USING gin(#{column} gin_trgm_ops);").and_call_original

    subject
  end

  it 'drops the renamed index' do
    expect(migration).to receive(:remove_concurrent_index_by_name).with(table, index_name_old).and_call_original

    subject
  end
end
