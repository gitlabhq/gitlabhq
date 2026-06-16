# frozen_string_literal: true

require 'spec_helper'
require './keeps/cleanup_unused_indexes/foreign_key_indexes'

RSpec.describe Keeps::CleanupUnusedIndexes::ForeignKeyIndexes, feature_category: :database do
  let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }
  let(:not_inherited_relation) { instance_double(ActiveRecord::Relation) }

  subject(:fk_indexes) { described_class.new(connection) }

  before do
    allow(Gitlab::Database::PostgresForeignKey).to receive(:not_inherited).and_return(not_inherited_relation)
    allow(Gitlab::Database::LooseForeignKeys).to receive(:definitions).and_return([])
  end

  def stub_hard_fks(pairs)
    # pairs => [[table, [col1, col2]], ...]
    allow(not_inherited_relation).to receive(:pluck)
      .with(:constrained_table_name, :constrained_columns)
      .and_return(pairs)
  end

  def index_double(name:, columns:)
    instance_double(ActiveRecord::ConnectionAdapters::IndexDefinition, name: name, columns: columns)
  end

  describe '#include?' do
    before do
      stub_hard_fks([['users', ['organization_id']]])
      allow(connection).to receive(:indexes).with('users').and_return([
        index_double(name: 'index_users_on_organization_id', columns: ['organization_id']),
        index_double(name: 'index_users_on_email', columns: ['email'])
      ])
    end

    it 'returns true for a schema-qualified identifier whose first column matches an FK column' do
      expect(fk_indexes.include?('public.index_users_on_organization_id')).to be(true)
    end

    it 'returns false for a bare index name (identifier must be schema-qualified)' do
      expect(fk_indexes.include?('index_users_on_organization_id')).to be(false)
    end

    it 'returns false for an index whose first column does not match' do
      expect(fk_indexes.include?('public.index_users_on_email')).to be(false)
    end

    it 'returns false for an unknown identifier' do
      expect(fk_indexes.include?('public.definitely_not_an_index')).to be(false)
    end
  end

  describe '#identifiers' do
    it 'memoises across calls' do
      stub_hard_fks([['users', ['foo']]])
      allow(connection).to receive(:indexes).with('users').and_return([])

      fk_indexes.identifiers
      fk_indexes.identifiers

      expect(connection).to have_received(:indexes).once
    end

    it 'handles composite FK columns by including indexes leading with any FK column' do
      stub_hard_fks([['users', %w[a b]]])
      allow(connection).to receive(:indexes).with('users').and_return([
        index_double(name: 'idx_a',     columns: ['a']),
        index_double(name: 'idx_b',     columns: ['b']),
        index_double(name: 'idx_other', columns: ['unrelated'])
      ])

      expect(fk_indexes.identifiers).to contain_exactly('public.idx_a', 'public.idx_b')
    end

    it 'includes loose foreign key supporting indexes' do
      stub_hard_fks([])
      lfk = instance_double(
        ActiveRecord::ConnectionAdapters::ForeignKeyDefinition,
        from_table: 'projects',
        column: 'namespace_id'
      )
      allow(Gitlab::Database::LooseForeignKeys).to receive(:definitions).and_return([lfk])
      allow(connection).to receive(:indexes).with('projects').and_return([
        index_double(name: 'index_projects_on_namespace_id', columns: ['namespace_id'])
      ])

      expect(fk_indexes.identifiers).to include('public.index_projects_on_namespace_id')
    end

    context 'when connection.indexes raises ActiveRecord::StatementInvalid for a table' do
      before do
        stub_hard_fks([['gone_table', ['col']]])
        allow(connection).to receive(:indexes).with('gone_table')
          .and_raise(ActiveRecord::StatementInvalid, 'relation does not exist')
      end

      it 'logs and continues, returning what was accumulated', :aggregate_failures do
        expect { fk_indexes.identifiers }.to output(/could not inspect gone_table/).to_stderr
        expect(fk_indexes.identifiers).to be_empty
      end
    end
  end
end
