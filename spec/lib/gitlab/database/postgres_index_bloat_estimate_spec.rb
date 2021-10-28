# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresIndexBloatEstimate do
  before do
    ActiveRecord::Base.connection.execute(<<~SQL)
      ANALYZE schema_migrations
    SQL
  end

  subject { described_class.find(identifier) }

  let(:identifier) { 'public.schema_migrations_pkey' }

  it { is_expected.to be_a Gitlab::Database::SharedModel }

  describe '#bloat_size' do
    it 'returns the bloat size in bytes' do
      # We cannot reach much more about the bloat size estimate here
      expect(subject.bloat_size).to be >= 0
    end
  end

  describe '#bloat_size_bytes' do
    it 'is an alias of #bloat_size' do
      expect(subject.bloat_size_bytes).to eq(subject.bloat_size)
    end
  end

  describe '#index' do
    it 'belongs to a PostgresIndex' do
      expect(subject.index.identifier).to eq(identifier)
    end
  end
end
