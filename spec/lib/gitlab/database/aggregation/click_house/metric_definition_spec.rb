# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::MetricDefinition, feature_category: :database do
  let(:scope_table) { Arel::Table.new('events') }
  let(:context) { { scope: scope_table, inner_query_name: 'ch_aggregation_inner_query' } }

  describe '#requires_window?' do
    it 'returns false' do
      metric = described_class.new(:event_count, :integer)

      expect(metric.requires_window?).to be(false)
    end
  end

  describe '#to_inner_arel' do
    context 'when no expression is provided' do
      it 'returns the scope column reference' do
        metric = described_class.new(:event_count, :integer)

        result = metric.to_inner_arel(context)

        expect(result).to be_a(Arel::Attributes::Attribute)
        expect(result.relation.name).to eq('events')
        expect(result.name).to eq('event_count')
      end
    end

    context 'when an expression is provided' do
      it 'calls the expression and returns its result' do
        expr = -> { Arel.sql('COUNT(*)') }
        metric = described_class.new(:event_count, :integer, expr)

        result = metric.to_inner_arel(context)

        expect(result.to_s).to eq('COUNT(*)')
      end
    end
  end

  describe '#to_outer_arel' do
    it 'returns a column reference from the inner query table' do
      metric = described_class.new(:event_count, :integer)
      outer_context = context.merge(local_alias: 'aeq_event_count')

      result = metric.to_outer_arel(outer_context)

      expect(result).to be_a(Arel::Attributes::Attribute)
      expect(result.relation.name).to eq('ch_aggregation_inner_query')
      expect(result.name).to eq('aeq_event_count')
    end

    it 'falls back to name when local_alias is not in context' do
      metric = described_class.new(:event_count, :integer)

      result = metric.to_outer_arel(context)

      expect(result).to be_a(Arel::Attributes::Attribute)
      expect(result.relation.name).to eq('ch_aggregation_inner_query')
      expect(result.name).to eq('event_count')
    end
  end
end
