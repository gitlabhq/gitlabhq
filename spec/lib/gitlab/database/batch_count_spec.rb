# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Database::BatchCount do
  let(:model) { Issue }
  let(:column) { :author_id }

  let(:in_transaction) { false }
  let(:user) { create(:user) }
  let(:another_user) { create(:user) }

  before do
    create_list(:issue, 3, author: user )
    create_list(:issue, 2, author: another_user )
    allow(ActiveRecord::Base.connection).to receive(:transaction_open?).and_return(in_transaction)
  end

  describe '#batch_count' do
    it 'counts table' do
      expect(described_class.batch_count(model)).to eq(5)
    end

    it 'counts with :id field' do
      expect(described_class.batch_count(model, :id)).to eq(5)
    end

    it 'counts with "id" field' do
      expect(described_class.batch_count(model, 'id')).to eq(5)
    end

    it 'counts with table.id field' do
      expect(described_class.batch_count(model, "#{model.table_name}.id")).to eq(5)
    end

    it 'counts table with batch_size 50K' do
      expect(described_class.batch_count(model, batch_size: 50_000)).to eq(5)
    end

    it 'will not count table with batch_size 1K' do
      fallback = ::Gitlab::Database::BatchCounter::FALLBACK
      expect(described_class.batch_count(model, batch_size: fallback / 2)).to eq(fallback)
    end

    it 'counts with a small edge case batch_sizes than result' do
      stub_const('Gitlab::Database::BatchCounter::MIN_REQUIRED_BATCH_SIZE', 0)

      [1, 2, 4, 5, 6].each { |i| expect(described_class.batch_count(model, batch_size: i)).to eq(5) }
    end

    context 'in a transaction' do
      let(:in_transaction) { true }

      it 'cannot count' do
        expect do
          described_class.batch_count(model)
        end.to raise_error 'BatchCount can not be run inside a transaction'
      end
    end
  end

  describe '#batch_distinct_count' do
    it 'counts with :id field' do
      expect(described_class.batch_distinct_count(model, :id)).to eq(5)
    end

    it 'counts with column field' do
      expect(described_class.batch_distinct_count(model, column)).to eq(2)
    end

    it 'counts with "id" field' do
      expect(described_class.batch_distinct_count(model, "#{column}")).to eq(2)
    end

    it 'counts with table.column field' do
      expect(described_class.batch_distinct_count(model, "#{model.table_name}.#{column}")).to eq(2)
    end

    it 'counts with :column field with batch_size of 50K' do
      expect(described_class.batch_distinct_count(model, column, batch_size: 50_000)).to eq(2)
    end

    it 'will not count table with batch_size 1K' do
      fallback = ::Gitlab::Database::BatchCounter::FALLBACK
      expect(described_class.batch_distinct_count(model, column, batch_size: fallback / 2)).to eq(fallback)
    end

    it 'counts with a small edge case batch_sizes than result' do
      stub_const('Gitlab::Database::BatchCounter::MIN_REQUIRED_BATCH_SIZE', 0)

      [1, 2, 4, 5, 6].each { |i| expect(described_class.batch_distinct_count(model, column, batch_size: i)).to eq(2) }
    end
  end
end
