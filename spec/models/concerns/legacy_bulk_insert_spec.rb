# frozen_string_literal: true

require 'spec_helper'

# rubocop: disable Gitlab/BulkInsert
RSpec.describe LegacyBulkInsert do
  let(:model) { ApplicationRecord }

  describe '#bulk_insert' do
    before do
      allow(model).to receive(:connection).and_return(dummy_connection)
      allow(dummy_connection).to receive(:quote_column_name, &:itself)
      allow(dummy_connection).to receive(:quote, &:itself)
      allow(dummy_connection).to receive(:execute)
    end

    let(:dummy_connection) { double(:connection) }

    let(:rows) do
      [
        { a: 1, b: 2, c: 3 },
        { c: 6, a: 4, b: 5 }
      ]
    end

    it 'does nothing with empty rows' do
      expect(dummy_connection).not_to receive(:execute)

      model.legacy_bulk_insert('test', [])
    end

    it 'uses the ordering from the first row' do
      expect(dummy_connection).to receive(:execute) do |sql|
        expect(sql).to include('(1, 2, 3)')
        expect(sql).to include('(4, 5, 6)')
      end

      model.legacy_bulk_insert('test', rows)
    end

    it 'quotes column names' do
      expect(dummy_connection).to receive(:quote_column_name).with(:a)
      expect(dummy_connection).to receive(:quote_column_name).with(:b)
      expect(dummy_connection).to receive(:quote_column_name).with(:c)

      model.legacy_bulk_insert('test', rows)
    end

    it 'quotes values' do
      1.upto(6) do |i|
        expect(dummy_connection).to receive(:quote).with(i)
      end

      model.legacy_bulk_insert('test', rows)
    end

    it 'does not quote values of a column in the disable_quote option' do
      [1, 2, 4, 5].each do |i|
        expect(dummy_connection).to receive(:quote).with(i)
      end

      model.legacy_bulk_insert('test', rows, disable_quote: :c)
    end

    it 'does not quote values of columns in the disable_quote option' do
      [2, 5].each do |i|
        expect(dummy_connection).to receive(:quote).with(i)
      end

      model.legacy_bulk_insert('test', rows, disable_quote: [:a, :c])
    end

    it 'handles non-UTF-8 data' do
      expect { model.legacy_bulk_insert('test', [{ a: "\255" }]) }.not_to raise_error
    end

    context 'when using PostgreSQL' do
      it 'allows the returning of the IDs of the inserted rows' do
        result = double(:result, values: [['10']])

        expect(dummy_connection)
          .to receive(:execute)
          .with(/RETURNING id/)
          .and_return(result)

        ids = model
          .legacy_bulk_insert('test', [{ number: 10 }], return_ids: true)

        expect(ids).to eq([10])
      end

      it 'allows setting the upsert to do nothing' do
        expect(dummy_connection)
          .to receive(:execute)
          .with(/ON CONFLICT DO NOTHING/)

        model
          .legacy_bulk_insert('test', [{ number: 10 }], on_conflict: :do_nothing)
      end
    end
  end
end
# rubocop: enable Gitlab/BulkInsert
