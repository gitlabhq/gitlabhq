# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BatchCount do
  let_it_be(:fallback) { ::Gitlab::Database::BatchCounter::FALLBACK }
  let_it_be(:small_batch_size) { ::Gitlab::Database::BatchCounter::MIN_REQUIRED_BATCH_SIZE - 1 }
  let(:model) { Issue }
  let(:column) { :author_id }

  let(:in_transaction) { false }

  let_it_be(:user) { create(:user) }
  let_it_be(:another_user) { create(:user) }

  before_all do
    create_list(:issue, 3, author: user)
    create_list(:issue, 2, author: another_user)
  end

  before do
    allow(ActiveRecord::Base.connection).to receive(:transaction_open?).and_return(in_transaction)
  end

  shared_examples 'disallowed configurations' do |method|
    it 'returns fallback if start is bigger than finish' do
      expect(described_class.public_send(method, *args, start: 1, finish: 0)).to eq(fallback)
    end

    it 'returns fallback if loops more than allowed' do
      large_finish = Gitlab::Database::BatchCounter::MAX_ALLOWED_LOOPS * default_batch_size + 1
      expect(described_class.public_send(method, *args, start: 1, finish: large_finish)).to eq(fallback)
    end

    it 'returns fallback if batch size is less than min required' do
      expect(described_class.public_send(method, *args, batch_size: small_batch_size)).to eq(fallback)
    end
  end

  shared_examples 'when a transaction is open' do
    let(:in_transaction) { true }

    it 'raises an error' do
      expect { subject }.to raise_error('BatchCount can not be run inside a transaction')
    end
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

    it 'counts with a start and finish' do
      expect(described_class.batch_count(model, start: model.minimum(:id), finish: model.maximum(:id))).to eq(5)
    end

    it "defaults the batch size to #{Gitlab::Database::BatchCounter::DEFAULT_BATCH_SIZE}" do
      min_id = model.minimum(:id)

      expect_next_instance_of(Gitlab::Database::BatchCounter) do |batch_counter|
        expect(batch_counter).to receive(:batch_fetch).with(min_id, Gitlab::Database::BatchCounter::DEFAULT_BATCH_SIZE + min_id, :itself).once.and_call_original
      end

      described_class.batch_count(model)
    end

    it_behaves_like 'when a transaction is open' do
      subject { described_class.batch_count(model) }
    end

    context 'disallowed_configurations' do
      include_examples 'disallowed configurations', :batch_count do
        let(:args) { [Issue] }
        let(:default_batch_size) { Gitlab::Database::BatchCounter::DEFAULT_BATCH_SIZE }
      end

      it 'raises an error if distinct count is requested' do
        expect { described_class.batch_count(model.distinct(column)) }.to raise_error 'Use distinct count for optimized distinct counting'
      end
    end

    context 'when a relation is grouped' do
      let!(:one_more_issue) { create(:issue, author: user, project: model.first.project) }

      before do
        stub_const('Gitlab::Database::BatchCounter::MIN_REQUIRED_BATCH_SIZE', 1)
      end

      context 'count by default column' do
        let(:count) do
          described_class.batch_count(model.group(column), batch_size: 2)
        end

        it 'counts grouped records' do
          expect(count).to eq({ user.id => 4, another_user.id => 2 })
        end
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

    it "defaults the batch size to #{Gitlab::Database::BatchCounter::DEFAULT_DISTINCT_BATCH_SIZE}" do
      min_id = model.minimum(:id)

      expect_next_instance_of(Gitlab::Database::BatchCounter) do |batch_counter|
        expect(batch_counter).to receive(:batch_fetch).with(min_id, Gitlab::Database::BatchCounter::DEFAULT_DISTINCT_BATCH_SIZE + min_id, :distinct).once.and_call_original
      end

      described_class.batch_distinct_count(model)
    end

    it_behaves_like 'when a transaction is open' do
      subject { described_class.batch_distinct_count(model, column) }
    end

    context 'disallowed configurations' do
      include_examples 'disallowed configurations', :batch_distinct_count do
        let(:args) { [model, column] }
        let(:default_batch_size) { Gitlab::Database::BatchCounter::DEFAULT_DISTINCT_BATCH_SIZE }
      end

      it 'will raise an error if distinct count with the :id column is requested' do
        expect do
          described_class.batch_count(described_class.batch_distinct_count(model, :id))
        end.to raise_error 'Use distinct count only with non id fields'
      end
    end

    context 'when a relation is grouped' do
      let!(:one_more_issue) { create(:issue, author: user, project: model.first.project) }

      before do
        stub_const('Gitlab::Database::BatchCounter::MIN_REQUIRED_BATCH_SIZE', 1)
      end

      context 'distinct count by non-unique column' do
        let(:count) do
          described_class.batch_distinct_count(model.group(column), :project_id, batch_size: 2)
        end

        it 'counts grouped records' do
          expect(count).to eq({ user.id => 3, another_user.id => 2 })
        end
      end
    end
  end

  describe '#batch_sum' do
    let(:column) { :weight }

    before do
      Issue.first.update_attribute(column, 3)
      Issue.last.update_attribute(column, 4)
    end

    it 'returns the sum of values in the given column' do
      expect(described_class.batch_sum(model, column)).to eq(7)
    end

    it 'works when given an Arel column' do
      expect(described_class.batch_sum(model, model.arel_table[column])).to eq(7)
    end

    it 'works with a batch size of 50K' do
      expect(described_class.batch_sum(model, column, batch_size: 50_000)).to eq(7)
    end

    it 'works with start and finish provided' do
      expect(described_class.batch_sum(model, column, start: model.minimum(:id), finish: model.maximum(:id))).to eq(7)
    end

    it 'returns the same result regardless of batch size' do
      stub_const('Gitlab::Database::BatchCounter::DEFAULT_SUM_BATCH_SIZE', 0)

      (1..(model.count + 1)).each { |i| expect(described_class.batch_sum(model, column, batch_size: i)).to eq(7) }
    end

    it "defaults the batch size to #{Gitlab::Database::BatchCounter::DEFAULT_SUM_BATCH_SIZE}" do
      min_id = model.minimum(:id)

      expect_next_instance_of(Gitlab::Database::BatchCounter) do |batch_counter|
        expect(batch_counter).to receive(:batch_fetch).with(min_id, Gitlab::Database::BatchCounter::DEFAULT_SUM_BATCH_SIZE + min_id, :itself).once.and_call_original
      end

      described_class.batch_sum(model, column)
    end

    it_behaves_like 'when a transaction is open' do
      subject { described_class.batch_sum(model, column) }
    end

    it_behaves_like 'disallowed configurations', :batch_sum do
      let(:args) { [model, column] }
      let(:default_batch_size) { Gitlab::Database::BatchCounter::DEFAULT_SUM_BATCH_SIZE }
      let(:small_batch_size) { Gitlab::Database::BatchCounter::DEFAULT_SUM_BATCH_SIZE - 1 }
    end
  end
end
