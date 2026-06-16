# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Batch::InclusiveCursorIterator, feature_category: :database do
  include Gitlab::Database::DynamicModelHelpers

  let(:connection) { ApplicationRecord.connection }
  let(:table_name) { :_test_cursor_batching }
  let(:cursor_columns) { %i[id_a id_b] }
  let(:model) do
    define_batchable_model(table_name, connection: connection, base_class: ApplicationRecord)
  end

  let(:scope) { model.order(*cursor_columns) }

  before do
    connection.execute(<<~SQL)
      CREATE TABLE _test_cursor_batching (
        id_a bigint NOT NULL,
        id_b bigint NOT NULL,
        payload text,
        PRIMARY KEY (id_a, id_b)
      );
      INSERT INTO _test_cursor_batching(id_a, id_b)
        SELECT i / 5, i % 5 FROM generate_series(0, 99) g(i);
    SQL
  end

  after do
    connection.drop_table(table_name)
  end

  describe '#initialize' do
    it 'raises when cursor_columns is empty' do
      expect do
        described_class.new(scope: scope, cursor_columns: [], start_cursor: [1, 2])
      end.to raise_error(ArgumentError, /cursor_columns must not be empty/)
    end

    it 'raises when start_cursor is nil' do
      expect do
        described_class.new(scope: scope, cursor_columns: cursor_columns, start_cursor: nil)
      end.to raise_error(ArgumentError, /must have one value per cursor column/)
    end

    it 'raises when start_cursor is empty' do
      expect do
        described_class.new(scope: scope, cursor_columns: cursor_columns, start_cursor: [])
      end.to raise_error(ArgumentError, /must have one value per cursor column/)
    end

    it 'raises when start_cursor arity mismatches cursor_columns' do
      expect do
        described_class.new(scope: scope, cursor_columns: cursor_columns, start_cursor: [1])
      end.to raise_error(ArgumentError, /must have one value per cursor column/)
    end
  end

  describe '#each_batch' do
    let(:start_cursor) { [0, 0] }

    subject(:iterator) do
      described_class.new(scope: scope, cursor_columns: cursor_columns, start_cursor: start_cursor)
    end

    it 'yields ActiveRecord::Relation instances' do
      iterator.each_batch(of: 7) do |batch|
        expect(batch).to be_a_kind_of(ActiveRecord::Relation)
      end
    end

    it 'yields every row in cursor order across all sub-batches' do
      yielded = []
      iterator.each_batch(of: 7) { |batch| yielded.concat(batch.to_a) }

      expect(yielded.map { |r| [r.id_a, r.id_b] }).to eq(scope.pluck(:id_a, :id_b))
    end

    it 'includes the row at start_cursor as the very first yielded row' do
      first_row = nil
      iterator.each_batch(of: 7) { |batch| first_row ||= batch.first }

      expect([first_row.id_a, first_row.id_b]).to eq(start_cursor)
    end

    context 'when start_cursor points to a middle row' do
      let(:start_cursor) { [10, 0] }

      it 'yields only rows at or after start_cursor, in cursor order' do
        yielded = []
        iterator.each_batch(of: 7) { |batch| yielded.concat(batch.to_a) }

        expected = scope.where('(id_a, id_b) >= (?, ?)', *start_cursor).pluck(:id_a, :id_b)
        expect(yielded.map { |r| [r.id_a, r.id_b] }).to eq(expected)
      end
    end

    context 'when matching rows fit in a single sub-batch (of > row count)' do
      it 'yields exactly one batch covering all rows and skips phase 2' do
        batches = []
        iterator.each_batch(of: 500) { |batch| batches << batch.to_a }

        expect(batches.size).to eq(1)
        expect(batches.first.map { |r| [r.id_a, r.id_b] }).to eq(scope.pluck(:id_a, :id_b))
      end
    end

    context 'when matching rows equal exactly one sub-batch (of == row count)' do
      it 'yields one full batch and skips phase 2' do
        batches = []
        iterator.each_batch(of: 100) { |batch| batches << batch.to_a }

        expect(batches.size).to eq(1)
        expect(batches.first.size).to eq(100)
      end
    end

    context 'when start_cursor is past the last row in scope' do
      let(:start_cursor) { [9999, 9999] }

      it 'yields a single empty relation and stops' do
        batches = []
        iterator.each_batch(of: 7) { |batch| batches << batch.to_a }

        expect(batches.size).to eq(1)
        expect(batches.first).to be_empty
      end
    end

    it 'emits inclusive `>=` against start_cursor in phase 1 and strict `>` in phase 2' do
      queries = []
      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
        event = ActiveSupport::Notifications::Event.new(*args)
        queries << event.payload[:sql]
      end

      begin
        iterator.each_batch(of: 7) { |batch| batch.to_a }
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      table_queries = queries.select { |q| q.include?('_test_cursor_batching') }
      tuple_gteq = /\("_test_cursor_batching"\."id_a", "_test_cursor_batching"\."id_b"\) >=/
      tuple_gt   = /\("_test_cursor_batching"\."id_a", "_test_cursor_batching"\."id_b"\) > \(/

      expect(table_queries).to include(a_string_matching(tuple_gteq)),
        'expected at least one phase 1 query using `(id_a, id_b) >=` against start_cursor'

      strict_only = table_queries.select { |q| q.match?(tuple_gt) && !q.match?(tuple_gteq) }
      expect(strict_only).not_to be_empty,
        'expected at least one phase 2 query using strict `(id_a, id_b) >` and no `>=`'

      mixed = table_queries.select { |q| q.match?(tuple_gteq) && q.match?(tuple_gt) }
      expect(mixed).to be_empty,
        'expected no sub-batch SQL to stack `>= start_cursor` and `> prev_cursor` (#599681)'
    end

    it 'hands phase 2 the cursor of the last row yielded by phase 1, not start_cursor' do
      captured_cursor = nil
      allow(Gitlab::Pagination::Keyset::Iterator).to receive(:new).and_wrap_original do |original, **kwargs|
        captured_cursor = kwargs[:cursor]
        original.call(**kwargs)
      end

      phase_1_rows = nil
      iterator.each_batch(of: 7) { |batch| phase_1_rows ||= batch.to_a }

      phase_1_last = phase_1_rows.last
      # cursor_attributes_for_node stringifies numeric values, so cast for comparison.
      captured_values = captured_cursor.values_at(:id_a, :id_b).map(&:to_i)

      expect(captured_cursor).not_to be_nil
      expect(captured_values).to eq([phase_1_last.id_a, phase_1_last.id_b])
      expect(captured_values).not_to eq(start_cursor)
    end
  end
end
