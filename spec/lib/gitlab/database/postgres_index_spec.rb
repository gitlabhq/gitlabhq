# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresIndex do
  before do
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE INDEX foo_idx ON public.users (name);
      CREATE UNIQUE INDEX bar_key ON public.users (id);

      CREATE TABLE example_table (id serial primary key);
    SQL
  end

  def find(name)
    described_class.by_identifier(name)
  end

  describe '.by_identifier' do
    it 'finds the index' do
      expect(find('public.foo_idx')).to be_a(Gitlab::Database::PostgresIndex)
    end

    it 'raises an error if not found' do
      expect { find('public.idontexist') }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'raises ArgumentError if given a non-fully qualified index name' do
      expect { find('foo') }.to raise_error(ArgumentError, /not fully qualified/)
    end
  end

  describe '.regular' do
    it 'only non-unique indexes' do
      expect(described_class.regular).to all(have_attributes(unique: false))
    end

    it 'only non partitioned indexes ' do
      expect(described_class.regular).to all(have_attributes(partitioned: false))
    end

    it 'only indexes that dont serve an exclusion constraint' do
      expect(described_class.regular).to all(have_attributes(exclusion: false))
    end
  end

  describe '.not_match' do
    it 'excludes indexes matching the given regex' do
      expect(described_class.not_match('^bar_k').map(&:name)).to all(match(/^(?!bar_k).*/))
    end

    it 'matches indexes without this prefix regex' do
      expect(described_class.not_match('^bar_k')).not_to be_empty
    end
  end

  describe '.random_few' do
    it 'limits to two records by default' do
      expect(described_class.random_few(2).size).to eq(2)
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

  describe '#valid_index?' do
    it 'returns true if the index is invalid' do
      expect(find('public.foo_idx')).to be_valid_index
    end

    it 'returns false if the index is marked as invalid' do
      ActiveRecord::Base.connection.execute(<<~SQL)
        UPDATE pg_index SET indisvalid=false
        FROM pg_class
        WHERE pg_class.relname = 'foo_idx' AND pg_index.indexrelid = pg_class.oid
      SQL

      expect(find('public.foo_idx')).not_to be_valid_index
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
