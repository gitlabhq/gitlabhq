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
        expr = ->(_params) { Arel.sql('COUNT(*)') }
        metric = described_class.new(:event_count, :integer, expr)

        result = metric.to_inner_arel(context)

        expect(result.to_s).to eq('COUNT(*)')
      end
    end
  end

  describe '#validate_part' do
    let(:query_plan) { instance_double(Gitlab::Database::Aggregation::QueryPlan) }

    def build_part(metric, configuration)
      Gitlab::Database::Aggregation::QueryPlan::BasePart.new(metric, configuration, query_plan: query_plan)
    end

    context 'when the metric has no parameters' do
      it 'adds no errors' do
        metric = described_class.new(:count, :integer)
        part = build_part(metric, { identifier: :count })
        part.valid?
        expect(part.errors[:base]).to be_empty
      end
    end

    context 'when the metric has a scalar parameter with in: constraint' do
      let(:metric) do
        described_class.new(:rate, :float, nil,
          parameters: { status: { type: :string, in: %w[success failed] } })
      end

      it 'adds no errors when the value is valid' do
        part = build_part(metric, { identifier: :rate, parameters: { status: 'success' } })
        part.valid?
        expect(part.errors[:status]).to be_empty
      end

      it 'adds an error when the value is invalid' do
        part = build_part(metric, { identifier: :rate, parameters: { status: 'bogus' } })
        part.valid?
        expect(part.errors[:status]).to include(a_string_matching(/Invalid value.*bogus/))
      end
    end

    context 'when the metric has an array: true parameter with in: constraint' do
      let(:metric) do
        described_class.new(:rate, :float, nil,
          parameters: { status: { type: :string, in: %w[success failed cancelled], array: true } })
      end

      it 'adds no errors when all values are valid' do
        part = build_part(metric, { identifier: :rate, parameters: { status: %w[success failed] } })
        part.valid?
        expect(part.errors[:status]).to be_empty
      end

      it 'adds an error listing only invalid elements' do
        part = build_part(metric, { identifier: :rate, parameters: { status: %w[success bogus] } })
        part.valid?
        expect(part.errors[:status]).to include(a_string_matching(/bogus/))
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
