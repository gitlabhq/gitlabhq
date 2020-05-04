# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Database::BatchCount do
  let_it_be(:fallback) { ::Gitlab::Database::BatchCounter::FALLBACK }
  let_it_be(:small_batch_size) { ::Gitlab::Database::BatchCounter::MIN_REQUIRED_BATCH_SIZE - 1 }
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

    it 'counts with Arel column' do
      expect(described_class.batch_count(model, model.arel_table[:id])).to eq(5)
    end

    it 'counts table with batch_size 50K' do
      expect(described_class.batch_count(model, batch_size: 50_000)).to eq(5)
    end

    it 'will not count table with a batch size less than allowed' do
      expect(described_class.batch_count(model, batch_size: small_batch_size)).to eq(fallback)
    end

    it 'counts with a small edge case batch_sizes than result' do
      stub_const('Gitlab::Database::BatchCounter::MIN_REQUIRED_BATCH_SIZE', 0)

      [1, 2, 4, 5, 6].each { |i| expect(described_class.batch_count(model, batch_size: i)).to eq(5) }
    end

    it 'will raise an error if distinct count is requested' do
      expect do
        described_class.batch_count(model.distinct(column))
      end.to raise_error 'Use distinct count for optimized distinct counting'
    end

    context 'in a transaction' do
      let(:in_transaction) { true }

      it 'cannot count' do
        expect do
          described_class.batch_count(model)
        end.to raise_error 'BatchCount can not be run inside a transaction'
      end
    end

    it 'counts with a start and finish' do
      expect(described_class.batch_count(model, start: model.minimum(:id), finish: model.maximum(:id))).to eq(5)
    end

    context 'disallowed configurations' do
      it 'returns fallback if start is bigger than finish' do
        expect(described_class.batch_count(model, start: 1, finish: 0)).to eq(fallback)
      end

      it 'returns fallback if loops more than allowed' do
        large_finish = Gitlab::Database::BatchCounter::MAX_ALLOWED_LOOPS * Gitlab::Database::BatchCounter::DEFAULT_BATCH_SIZE + 1
        expect(described_class.batch_count(model, start: 1, finish: large_finish)).to eq(fallback)
      end

      it 'returns fallback if batch size is less than min required' do
        expect(described_class.batch_count(model, batch_size: small_batch_size)).to eq(fallback)
      end
    end
  end

  describe '#batch_distinct_count' do
    it 'counts with column field' do
      expect(described_class.batch_distinct_count(model, column)).to eq(2)
    end

    it 'counts with "id" field' do
      expect(described_class.batch_distinct_count(model, "#{column}")).to eq(2)
    end

    it 'counts with table.column field' do
      expect(described_class.batch_distinct_count(model, "#{model.table_name}.#{column}")).to eq(2)
    end

    it 'counts with Arel column' do
      expect(described_class.batch_distinct_count(model, model.arel_table[column])).to eq(2)
    end

    it 'counts with :column field with batch_size of 50K' do
      expect(described_class.batch_distinct_count(model, column, batch_size: 50_000)).to eq(2)
    end

    it 'will not count table with a batch size less than allowed' do
      expect(described_class.batch_distinct_count(model, column, batch_size: small_batch_size)).to eq(fallback)
    end

    it 'counts with a small edge case batch_sizes than result' do
      stub_const('Gitlab::Database::BatchCounter::MIN_REQUIRED_BATCH_SIZE', 0)

      [1, 2, 4, 5, 6].each { |i| expect(described_class.batch_distinct_count(model, column, batch_size: i)).to eq(2) }
    end

    it 'counts with a start and finish' do
      expect(described_class.batch_distinct_count(model, column, start: model.minimum(column), finish: model.maximum(column))).to eq(2)
    end

    it 'counts with User min and max as start and finish' do
      expect(described_class.batch_distinct_count(model, column, start: User.minimum(:id), finish: User.maximum(:id))).to eq(2)
    end

    context 'disallowed configurations' do
      it 'returns fallback if start is bigger than finish' do
        expect(described_class.batch_distinct_count(model, column, start: 1, finish: 0)).to eq(fallback)
      end

      it 'returns fallback if loops more than allowed' do
        large_finish = Gitlab::Database::BatchCounter::MAX_ALLOWED_LOOPS * Gitlab::Database::BatchCounter::DEFAULT_DISTINCT_BATCH_SIZE + 1
        expect(described_class.batch_distinct_count(model, column, start: 1, finish: large_finish)).to eq(fallback)
      end

      it 'returns fallback if batch size is less than min required' do
        expect(described_class.batch_distinct_count(model, column, batch_size: small_batch_size)).to eq(fallback)
      end

      it 'will raise an error if distinct count with the :id column is requested' do
        expect do
          described_class.batch_count(described_class.batch_distinct_count(model, :id))
        end.to raise_error 'Use distinct count only with non id fields'
      end
    end
  end
end
