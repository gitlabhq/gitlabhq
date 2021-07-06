# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresIndex do
  let(:schema) { 'public' }
  let(:name) { 'foo_idx' }
  let(:identifier) { "#{schema}.#{name}" }

  before do
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE INDEX #{name} ON public.users (name);
      CREATE UNIQUE INDEX bar_key ON public.users (id);

      CREATE TABLE example_table (id serial primary key);
    SQL
  end

  def find(name)
    described_class.by_identifier(name)
  end

  it_behaves_like 'a postgres model'

  describe '.regular' do
    it 'only non-unique indexes' do
      expect(described_class.regular).to all(have_attributes(unique: false))
    end

    it 'only non partitioned indexes' do
      expect(described_class.regular).to all(have_attributes(partitioned: false))
    end

    it 'only indexes that dont serve an exclusion constraint' do
      expect(described_class.regular).to all(have_attributes(exclusion: false))
    end

    it 'only non-expression indexes' do
      expect(described_class.regular).to all(have_attributes(expression: false))
    end
  end

  describe '.reindexing_support' do
    it 'only non partitioned indexes' do
      expect(described_class.reindexing_support).to all(have_attributes(partitioned: false))
    end

    it 'only indexes that dont serve an exclusion constraint' do
      expect(described_class.reindexing_support).to all(have_attributes(exclusion: false))
    end

    it 'only non-expression indexes' do
      expect(described_class.reindexing_support).to all(have_attributes(expression: false))
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

  describe '#bloat_size' do
    subject { build(:postgres_index, bloat_estimate: bloat_estimate) }

    let(:bloat_estimate) { build(:postgres_index_bloat_estimate) }
    let(:bloat_size) { double }

    it 'returns the bloat size from the estimate' do
      expect(bloat_estimate).to receive(:bloat_size).and_return(bloat_size)

      expect(subject.bloat_size).to eq(bloat_size)
    end

    context 'without a bloat estimate available' do
      let(:bloat_estimate) { nil }

      it 'returns 0' do
        expect(subject.bloat_size).to eq(0)
      end
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
      expect(find(identifier)).to be_valid_index
    end

    it 'returns false if the index is marked as invalid' do
      ActiveRecord::Base.connection.execute(<<~SQL)
        UPDATE pg_index SET indisvalid=false
        FROM pg_class
        WHERE pg_class.relname = 'foo_idx' AND pg_index.indexrelid = pg_class.oid
      SQL

      expect(find(identifier)).not_to be_valid_index
    end
  end

  describe '#definition' do
    it 'returns the index definition' do
      expect(find(identifier).definition).to eq('CREATE INDEX foo_idx ON public.users USING btree (name)')
    end
  end
end
