# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Type::SymbolizedJsonb do
  let(:type) { described_class.new }

  describe '#deserialize' do
    using RSpec::Parameterized::TableSyntax

    subject { type.deserialize(json) }

    where(:json, :value) do
      nil                                   | nil
      '{"key":"value"}'                     | { key: 'value' }
      '{"key":[1,2,3]}'                     | { key: [1, 2, 3] }
      '{"key":{"subkey":"value"}}'          | { key: { subkey: 'value' } }
      '{"key":{"a":[{"b":"c"},{"d":"e"}]}}' | { key: { a: [{ b: 'c' }, { d: 'e' }] } }
    end

    with_them do
      it { is_expected.to match(value) }
    end
  end

  context 'when used by a model' do
    let(:model) do
      Class.new(ApplicationRecord) do
        self.table_name = :_test_symbolized_jsonb

        attribute :options, ::Gitlab::Database::Type::SymbolizedJsonb.new
      end
    end

    let(:record) do
      model.create!(name: 'test', options: { key: 'value' })
    end

    before do
      ApplicationRecord.connection.execute(<<~SQL)
        CREATE TABLE _test_symbolized_jsonb(
          id serial NOT NULL PRIMARY KEY,
          name text,
          options jsonb);
      SQL

      model.reset_column_information
    end

    it { expect(record.options).to match({ key: 'value' }) }

    it 'ignores changes to other attributes' do
      record.name = 'other test'

      expect(record.changes).to match('name' => ['test', 'other test'])
    end

    it 'tracks changes to options' do
      record.options = { key: 'other value' }

      expect(record.changes).to match('options' => [{ 'key' => 'value' }, { 'key' => 'other value' }])
    end
  end
end
