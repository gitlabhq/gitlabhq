# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BatchAverageCounter do
  let(:model)  { Issue }
  let(:column) { :weight }

  let(:in_transaction) { false }

  before do
    allow(model.connection).to receive(:transaction_open?).and_return(in_transaction)
  end

  describe '#count' do
    before do
      create_list(:issue, 2, weight: 4)
      create_list(:issue, 2, weight: 2)
      create_list(:issue, 2, weight: 3)
    end

    subject(:batch_average_counter) { described_class.new(model, column) }

    it 'returns correct average of weights' do
      expect(subject.count).to eq(3.0)
    end

    it 'does no raise an exception if transaction is not open' do
      expect { subject.count }.not_to raise_error
    end

    context 'when transaction is open' do
      let(:in_transaction) { true }

      it 'raises an error' do
        expect { subject.count }.to raise_error('BatchAverageCounter can not be run inside a transaction')
      end
    end

    context 'when batch size is small' do
      let(:batch_size) { 2 }

      it 'returns correct average of weights' do
        expect(subject.count(batch_size: batch_size)).to eq(3.0)
      end
    end

    context 'when column passed is an Arel attribute' do
      let(:column) { model.arel_table[:weight] }

      it 'returns correct average of weights' do
        expect(subject.count).to eq(3.0)
      end
    end

    context 'when column has total count of zero' do
      before do
        Issue.update_all(weight: nil)
      end

      it 'returns the fallback value' do
        expect(subject.count).to eq(-1)
      end
    end

    context 'when one batch has nil weights (no average)' do
      before do
        issues = Issue.where(weight: 4)
        issues.update_all(weight: nil)
      end

      let(:batch_size) { 2 }

      it 'calculates average of weights with no errors' do
        expect(subject.count(batch_size: batch_size)).to eq(2.5)
      end
    end

    context 'when batch fetch query is cancelled' do
      let(:batch_size) { 22_000 }
      let(:relation) { instance_double(ActiveRecord::Relation, to_sql: batch_average_query) }

      context 'when all retries fail' do
        let(:batch_average_query) { 'SELECT AVG(weight) FROM issues WHERE weight BETWEEN 2 and 5' }
        let(:query_timed_out_exception) { ActiveRecord::QueryCanceled.new('query timed out') }

        before do
          allow(model).to receive(:where).and_return(relation)
          allow(relation).to receive(:pick).and_raise(query_timed_out_exception)
        end

        it 'logs failing query' do
          expect(Gitlab::AppJsonLogger).to receive(:error).with(
            event: 'batch_count',
            relation: model.table_name,
            operation: 'average',
            start: 2,
            query: batch_average_query,
            message: 'Query has been canceled with message: query timed out'
          )

          expect(subject.count(batch_size: batch_size)).to eq(-1)
        end
      end
    end
  end
end
