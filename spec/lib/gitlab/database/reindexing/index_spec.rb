# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Reindexing::Index do
  before do
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE INDEX foo_idx ON public.users (name);
      CREATE UNIQUE INDEX bar_key ON public.users (id);

      CREATE TABLE example_table (id serial primary key);
    SQL
  end

  def find(name)
    described_class.find_with_schema(name)
  end

  describe '.find_with_schema' do
    it 'returns an instance of Gitlab::Database::Reindexing::Index when the index is present' do
      expect(find('public.foo_idx')).to be_a(Gitlab::Database::Reindexing::Index)
    end

    it 'returns nil if the index is not present' do
      expect(find('public.idontexist')).to be_nil
    end

    it 'raises ArgumentError if given a non-fully qualified index name' do
      expect { find('foo') }.to raise_error(ArgumentError, /not fully qualified/)
    end
  end

  describe '#unique?' do
    it 'returns true for a unique index' do
      expect(find('public.bar_key')).to be_unique
    end

    it 'returns false for a regular, non-unique index' do
      expect(find('public.foo_idx')).not_to be_unique
    end

    it 'returns true for a primary key index' do
      expect(find('public.example_table_pkey')).to be_unique
    end
  end

  describe '#valid?' do
    it 'returns true if the index is valid' do
      expect(find('public.foo_idx')).to be_valid
    end

    it 'returns false if the index is marked as invalid' do
      ActiveRecord::Base.connection.execute(<<~SQL)
        UPDATE pg_index SET indisvalid=false
        FROM pg_class
        WHERE pg_class.relname = 'foo_idx' AND pg_index.indexrelid = pg_class.oid
      SQL

      expect(find('public.foo_idx')).not_to be_valid
    end
  end

  describe '#to_s' do
    it 'returns the index name' do
      expect(find('public.foo_idx').to_s).to eq('foo_idx')
    end
  end

  describe '#name' do
    it 'returns the name' do
      expect(find('public.foo_idx').name).to eq('foo_idx')
    end
  end

  describe '#schema' do
    it 'returns the index schema' do
      expect(find('public.foo_idx').schema).to eq('public')
    end
  end

  describe '#definition' do
    it 'returns the index definition' do
      expect(find('public.foo_idx').definition).to eq('CREATE INDEX foo_idx ON public.users USING btree (name)')
    end
  end
end
