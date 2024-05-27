# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BatchCount do
  let_it_be(:fallback) { ::Gitlab::Database::BatchCounter::FALLBACK }
  let_it_be(:small_batch_size) { calculate_batch_size(::Gitlab::Database::BatchCounter::MIN_REQUIRED_BATCH_SIZE) }
  let_it_be(:max_allowed_loops) { ::Gitlab::Database::BatchCounter::MAX_ALLOWED_LOOPS }
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
    allow(model.connection).to receive(:transaction_open?).and_return(in_transaction)
  end

  def calculate_batch_size(batch_size)
    zero_offset_modifier = -1

    batch_size + zero_offset_modifier
  end

  shared_examples 'disallowed configurations' do |method|
    it 'returns fallback if start is bigger than finish' do
      expect(described_class.public_send(method, *args, start: 1, finish: 0)).to eq(fallback)
    end

    it 'returns fallback if loops more than allowed' do
      large_finish = (max_allowed_loops * default_batch_size) + 1
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

  shared_examples 'when batch fetch query is canceled' do
    let(:batch_size) { 22_000 }
    let(:relation) { instance_double(ActiveRecord::Relation) }

    it 'reduces batch size by half and retry fetch' do
      too_big_batch_relation_mock = instance_double(ActiveRecord::Relation)
      allow(model).to receive_message_chain(:select, public_send: relation)
      allow(relation).to receive(:where).with({ "id" => 0..calculate_batch_size(batch_size) }).and_return(too_big_batch_relation_mock)
      allow(too_big_batch_relation_mock).to receive(:send).and_raise(ActiveRecord::QueryCanceled)

      expect(relation).to receive(:where).with({ "id" => 0..calculate_batch_size(batch_size / 2) }).and_return(double(send: 1))

      subject.call(model, column, batch_size: batch_size, start: 0)
    end

    context 'when all retries fail' do
      let(:batch_count_query) { 'SELECT COUNT(id) FROM relation WHERE id BETWEEN 0 and 1' }

      before do
        allow(model).to receive_message_chain(:select, :public_send, where: relation)
        allow(relation).to receive(:send).and_raise(ActiveRecord::QueryCanceled.new('query timed out'))
        allow(relation).to receive(:to_sql).and_return(batch_count_query)
      end

      it 'logs failing query' do
        expect(Gitlab::AppJsonLogger).to receive(:error).with(
          event: 'batch_count',
          relation: model.table_name,
          operation: operation,
          operation_args: operation_args,
          max_allowed_loops: max_allowed_loops,
          start: 0,
          mode: mode,
          query: batch_count_query,
          message: 'Query has been canceled with message: query timed out'
        )
        expect(subject.call(model, column, batch_size: batch_size, start: 0)).to eq(fallback)
      end
    end
  end

  describe '#batch_count' do
    it 'counts table' do
      expect(described_class.batch_count(model)).to eq(model.count)
    end

    it 'counts with :id field' do
      expect(described_class.batch_count(model, :id)).to eq(model.count)
    end

    it 'counts with "id" field' do
      expect(described_class.batch_count(model, 'id')).to eq(model.count)
    end

    it 'counts with table.id field' do
      expect(described_class.batch_count(model, "#{model.table_name}.id")).to eq(model.count)
    end

    it 'counts with Arel column' do
      expect(described_class.batch_count(model, model.arel_table[:id])).to eq(model.count)
    end

    it 'counts table with batch_size 50K' do
      expect(described_class.batch_count(model, batch_size: 50_000)).to eq(model.count)
    end

    it 'will not count table with a batch size less than allowed' do
      expect(described_class.batch_count(model, batch_size: small_batch_size)).to eq(fallback)
    end

    it 'produces the same result with different batch sizes' do
      stub_const('Gitlab::Database::BatchCounter::MIN_REQUIRED_BATCH_SIZE', 0)

      [1, 2, 4, 5, 6].each { |i| expect(described_class.batch_count(model, batch_size: i)).to eq(model.count) }
    end

    it 'counts with a start and finish' do
      expect(described_class.batch_count(model, start: model.minimum(:id), finish: model.maximum(:id))).to eq(model.count)
    end

    it 'stops counting when finish value is reached' do
      stub_const('Gitlab::Database::BatchCounter::MIN_REQUIRED_BATCH_SIZE', 0)

      expect(described_class.batch_count(model,
        start: model.minimum(:id),
        finish: model.maximum(:id) - 1, # Do not count the last record
        batch_size: model.count - 2 # Ensure there are multiple batches
      )).to eq(model.count - 1)
    end

    it "defaults the batch size to #{Gitlab::Database::BatchCounter::DEFAULT_BATCH_SIZE}" do
      min_id = model.minimum(:id)
      relation = instance_double(ActiveRecord::Relation)
      allow(model).to receive_message_chain(:select, public_send: relation)
      batch_end_id = min_id + calculate_batch_size(Gitlab::Database::BatchCounter::DEFAULT_BATCH_SIZE)

      expect(relation).to receive(:where).with({ "id" => min_id..batch_end_id }).and_return(double(send: 1))

      described_class.batch_count(model)
    end

    it 'does not use BETWEEN to define the range' do
      batch_size = Gitlab::Database::BatchCounter::MIN_REQUIRED_BATCH_SIZE + 1
      issue = nil

      travel_to(Date.tomorrow) do
        issue = create(:issue) # created_at: 00:00:00
        create(:issue, created_at: issue.created_at + batch_size - 0.5) # created_at: 00:20:50.5
        create(:issue, created_at: issue.created_at + batch_size) # created_at: 00:20:51
      end

      # When using BETWEEN, the range condition looks like:
      # Batch 1: WHERE "issues"."created_at" BETWEEN "2020-10-09 00:00:00" AND "2020-10-09 00:20:50"
      # Batch 2: WHERE "issues"."created_at" BETWEEN "2020-10-09 00:20:51" AND "2020-10-09 00:41:41"
      # We miss the issue created at 00:20:50.5 because we prevent the batches from overlapping (start..(finish - 1))
      # See https://wiki.postgresql.org/wiki/Don't_Do_This#Don.27t_use_BETWEEN_.28especially_with_timestamps.29

      # When using >= AND <, we eliminate any gaps between batches (start...finish)
      # This is useful when iterating over a timestamp column
      # Batch 1: WHERE "issues"."created_at" >= "2020-10-09 00:00:00" AND "issues"."created_at" < "2020-10-09 00:20:51"
      # Batch 1: WHERE "issues"."created_at" >= "2020-10-09 00:20:51" AND "issues"."created_at" < "2020-10-09 00:41:42"
      expect(described_class.batch_count(model, :created_at, batch_size: batch_size, start: issue.created_at)).to eq(3)
    end

    it_behaves_like 'when a transaction is open' do
      subject { described_class.batch_count(model) }
    end

    it_behaves_like 'when batch fetch query is canceled' do
      let(:mode) { :itself }
      let(:operation) { :count }
      let(:operation_args) { nil }
      let(:column) { nil }

      subject { described_class.method(:batch_count) }
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

  describe '#batch_count_with_timeout' do
    it 'counts table' do
      expect(described_class.batch_count_with_timeout(model)).to eq({ status: :completed, count: model.count })
    end

    it 'counts with :id field' do
      expect(described_class.batch_count_with_timeout(model, :id)).to eq({ status: :completed, count: model.count })
    end

    it 'counts with "id" field' do
      expect(described_class.batch_count_with_timeout(model, 'id')).to eq({ status: :completed, count: model.count })
    end

    it 'counts with table.id field' do
      expect(described_class.batch_count_with_timeout(model, "#{model.table_name}.id")).to eq({ status: :completed, count: model.count })
    end

    it 'counts with Arel column' do
      expect(described_class.batch_count_with_timeout(model, model.arel_table[:id])).to eq({ status: :completed, count: model.count })
    end

    it 'counts table with batch_size 50K' do
      expect(described_class.batch_count_with_timeout(model, batch_size: 50_000)).to eq({ status: :completed, count: model.count })
    end

    it 'will not count table with a batch size less than allowed' do
      expect(described_class.batch_count_with_timeout(model, batch_size: small_batch_size)).to eq({ status: :bad_config })
    end

    it 'produces the same result with different batch sizes' do
      stub_const('Gitlab::Database::BatchCounter::MIN_REQUIRED_BATCH_SIZE', 0)

      [1, 2, 4, 5, 6].each { |i| expect(described_class.batch_count_with_timeout(model, batch_size: i)).to eq({ status: :completed, count: model.count }) }
    end

    it 'counts with a start and finish' do
      expect(described_class.batch_count_with_timeout(model, start: model.minimum(:id), finish: model.maximum(:id))).to eq({ status: :completed, count: model.count })
    end

    it 'stops counting when finish value is reached' do
      stub_const('Gitlab::Database::BatchCounter::MIN_REQUIRED_BATCH_SIZE', 0)

      expect(described_class.batch_count_with_timeout(model,
        start: model.minimum(:id),
        finish: model.maximum(:id) - 1, # Do not count the last record
        batch_size: model.count - 2 # Ensure there are multiple batches
      )).to eq({ status: :completed, count: model.count - 1 })
    end

    it 'returns a partial count when timeout elapses' do
      stub_const('Gitlab::Database::BatchCounter::MIN_REQUIRED_BATCH_SIZE', 0)

      expect(::Gitlab::Metrics::System).to receive(:monotonic_time).and_return(1, 10, 300)

      expect(
        described_class.batch_count_with_timeout(model, batch_size: 1, timeout: 250.seconds)
      ).to eq({ status: :timeout, partial_results: 1, continue_from: model.minimum(:id) + 1 })
    end

    it 'starts counting from a given partial result' do
      expect(described_class.batch_count_with_timeout(model, partial_results: 3)).to eq({ status: :completed, count: 3 + model.count })
    end

    it_behaves_like 'when a transaction is open' do
      subject { described_class.batch_count_with_timeout(model) }
    end

    it_behaves_like 'when batch fetch query is canceled' do
      let(:mode) { :itself }
      let(:operation) { :count }
      let(:operation_args) { nil }
      let(:column) { nil }
      let(:fallback) { { status: :cancelled } }

      subject { described_class.method(:batch_count_with_timeout) }
    end

    context 'disallowed_configurations' do
      include_examples 'disallowed configurations', :batch_count do
        let(:args) { [Issue] }
        let(:default_batch_size) { Gitlab::Database::BatchCounter::DEFAULT_BATCH_SIZE }
      end

      it 'raises an error if distinct count is requested' do
        expect { described_class.batch_count_with_timeout(model.distinct(column)) }.to raise_error 'Use distinct count for optimized distinct counting'
      end
    end

    context 'when a relation is grouped' do
      let!(:one_more_issue) { create(:issue, author: user, project: model.first.project) }

      before do
        stub_const('Gitlab::Database::BatchCounter::MIN_REQUIRED_BATCH_SIZE', 1)
      end

      context 'count by default column' do
        let(:count) do
          described_class.batch_count_with_timeout(model.group(column), batch_size: 2)
        end

        it 'counts grouped records' do
          expect(count).to eq({ status: :completed, count: { user.id => 4, another_user.id => 2 } })
        end
      end
    end
  end

  describe '#batch_distinct_count' do
    it 'counts with column field' do
      expect(described_class.batch_distinct_count(model, column)).to eq(2)
    end

    it 'counts with "id" field' do
      expect(described_class.batch_distinct_count(model, column.to_s)).to eq(2)
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

    it 'produces the same result with different batch sizes' do
      stub_const('Gitlab::Database::BatchCounter::MIN_REQUIRED_BATCH_SIZE', 0)

      [1, 2, 4, 5, 6].each { |i| expect(described_class.batch_distinct_count(model, column, batch_size: i)).to eq(2) }
    end

    it 'counts with a start and finish' do
      expect(described_class.batch_distinct_count(model, column, start: model.minimum(column), finish: model.maximum(column))).to eq(2)
    end

    it 'stops counting when finish value is reached' do
      # Create a new unique author that should not be counted
      create(:issue)

      stub_const('Gitlab::Database::BatchCounter::MIN_REQUIRED_BATCH_SIZE', 0)

      expect(described_class.batch_distinct_count(model, column,
        start: User.minimum(:id),
        finish: User.maximum(:id) - 1, # Do not count the newly created issue
        batch_size: model.count - 2 # Ensure there are multiple batches
      )).to eq(2)
    end

    it 'counts with User min and max as start and finish' do
      expect(described_class.batch_distinct_count(model, column, start: User.minimum(:id), finish: User.maximum(:id))).to eq(2)
    end

    it "defaults the batch size to #{Gitlab::Database::BatchCounter::DEFAULT_DISTINCT_BATCH_SIZE}" do
      min_id = model.minimum(:id)
      relation = instance_double(ActiveRecord::Relation)
      allow(model).to receive_message_chain(:select, public_send: relation)
      batch_end_id = min_id + calculate_batch_size(Gitlab::Database::BatchCounter::DEFAULT_DISTINCT_BATCH_SIZE)

      expect(relation).to receive(:where).with({ "id" => min_id..batch_end_id }).and_return(double(send: 1))

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

    it_behaves_like 'when batch fetch query is canceled' do
      let(:mode) { :distinct }
      let(:operation) { :count }
      let(:operation_args) { nil }
      let(:column) { nil }

      subject { described_class.method(:batch_distinct_count) }
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
      relation = instance_double(ActiveRecord::Relation)
      allow(model).to receive_message_chain(:select, public_send: relation)
      batch_end_id = min_id + calculate_batch_size(Gitlab::Database::BatchCounter::DEFAULT_SUM_BATCH_SIZE)

      expect(relation).to receive(:where).with({ "id" => min_id..batch_end_id }).and_return(double(send: 1))

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

    it_behaves_like 'when batch fetch query is canceled' do
      let(:mode) { :itself }
      let(:operation) { :sum }
      let(:operation_args) { [column] }

      subject { described_class.method(:batch_sum) }
    end
  end

  describe '#batch_average' do
    let(:column) { :weight }

    before do
      allow_next_instance_of(Gitlab::Database::BatchAverageCounter) do |instance|
        allow(instance).to receive(:count).and_return
      end
    end

    it 'calls BatchAverageCounter' do
      expect(Gitlab::Database::BatchAverageCounter).to receive(:new).with(model, column).and_call_original

      described_class.batch_average(model, column)
    end
  end
end
