# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::DimensionDefinition, feature_category: :database do
  let(:scope_table) { Arel::Table.new('events') }
  let(:context) { { scope: scope_table, inner_query_name: 'ch_aggregation_inner_query' } }

  describe '#requires_window?' do
    it 'returns false' do
      dimension = described_class.new(:event_date, :date)

      expect(dimension.requires_window?).to be(false)
    end
  end

  describe '#to_inner_arel' do
    context 'when no expression is provided' do
      it 'returns the scope column reference' do
        dimension = described_class.new(:event_date, :date)

        result = dimension.to_inner_arel(context)

        expect(result).to be_a(Arel::Attributes::Attribute)
        expect(result.relation.name).to eq('events')
        expect(result.name).to eq('event_date')
      end
    end

    context 'when an expression is provided' do
      it 'calls the expression and returns its result' do
        expr = -> { Arel.sql('toDate(created_at)') }
        dimension = described_class.new(:event_date, :date, expr)

        result = dimension.to_inner_arel(context)

        expect(result.to_s).to eq('toDate(created_at)')
      end
    end
  end

  describe '#to_outer_arel' do
    it 'returns a column reference from the inner query table' do
      dimension = described_class.new(:event_date, :date)
      outer_context = context.merge(local_alias: 'aeq_event_date')

      result = dimension.to_outer_arel(outer_context)

      expect(result).to be_a(Arel::Attributes::Attribute)
      expect(result.relation.name).to eq('ch_aggregation_inner_query')
      expect(result.name).to eq('aeq_event_date')
    end

    it 'falls back to name when local_alias is not in context' do
      dimension = described_class.new(:event_date, :date)

      result = dimension.to_outer_arel(context)

      expect(result).to be_a(Arel::Attributes::Attribute)
      expect(result.relation.name).to eq('ch_aggregation_inner_query')
      expect(result.name).to eq('event_date')
    end
  end
end
