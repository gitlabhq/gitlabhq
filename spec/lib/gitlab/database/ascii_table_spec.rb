# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Database::AsciiTable, feature_category: :database do
  describe '#lines' do
    it 'aligns columns and puts a rule under the headers' do
      table = described_class.new(
        [%w[public postgres], %w[very_long_schema_name gitlab]],
        headers: %w[SCHEMA OWNER]
      )

      expect(table.lines).to eq(
        [
          'SCHEMA                 OWNER   ',
          '---------------------  --------',
          'public                 postgres',
          'very_long_schema_name  gitlab  '
        ])
    end

    it 'renders only the rows without headers' do
      table = described_class.new([%w[a b], %w[cc d]])

      expect(table.lines).to eq(['a   b', 'cc  d'])
    end

    it 'skips the header line when headers are empty' do
      table = described_class.new([%w[a b]], headers: [])

      expect(table.lines).to eq(['a  b'])
    end

    it 'joins cells and the rule with the given gaps' do
      table = described_class.new([%w[a b]], headers: %w[id name], gap: ' | ', rule_gap: '-|-')

      expect(table.lines).to eq(['id | name', '---|-----', 'a  | b   '])
    end

    it 'stringifies cells and headers' do
      table = described_class.new([[1, nil]], headers: [:id, :name])

      expect(table.lines).to eq(['id  name', '--  ----', '1       '])
    end

    it 'renders headers and the rule when there are no rows' do
      table = described_class.new([], headers: %w[id name])

      expect(table.lines).to eq(['id  name', '--  ----'])
    end
  end
end
