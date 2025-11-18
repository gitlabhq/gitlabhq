# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CreateNamespaceIsolations, migration: :gitlab_main, feature_category: :organization do
  let(:migration) { described_class.new }
  let(:namespace_isolations) { table(:namespace_isolations) }

  describe '#up' do
    it 'creates the namespace_isolations table' do
      migrate!

      expect(namespace_isolations.table_exists?).to be true
    end

    it 'creates the table with the correct columns' do
      migrate!

      expect(namespace_isolations.column_names).to include(
        'id', 'namespace_id', 'isolated', 'created_at', 'updated_at'
      )
    end

    it 'sets the correct column types and constraints' do
      migrate!

      namespace_id_column = namespace_isolations.columns.find { |c| c.name == 'namespace_id' }
      isolated_column = namespace_isolations.columns.find { |c| c.name == 'isolated' }

      expect(namespace_id_column.type).to eq(:integer)
      expect(namespace_id_column.null).to be false

      expect(isolated_column.type).to eq(:boolean)
      expect(isolated_column.null).to be false
      expect(isolated_column.default).to eq "false"
    end

    it 'creates the unique index on namespace_id' do
      migrate!

      indexes = ActiveRecord::Base.connection.indexes(:namespace_isolations)
      namespace_id_index = indexes.find { |i| i.columns == ['namespace_id'] }

      expect(namespace_id_index).to be_present
      expect(namespace_id_index.unique).to be true
    end

    it 'creates the foreign key constraint on namespace_id' do
      migrate!

      foreign_keys = ActiveRecord::Base.connection.foreign_keys(:namespace_isolations)
      namespace_fk = foreign_keys.find { |fk| fk.column == 'namespace_id' }

      expect(namespace_fk).to be_present
      expect(namespace_fk.to_table).to eq('namespaces')
      expect(namespace_fk.on_delete).to eq(:cascade)
    end
  end

  describe '#down' do
    it 'drops the namespace_isolations table' do
      migrate!
      schema_migrate_down!

      expect(namespace_isolations.table_exists?).to be false
    end
  end
end
