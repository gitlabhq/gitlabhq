# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::BitmapWindow, feature_category: :database do
  let(:scope_table) { Arel::Table.new('events') }
  let(:context) { { scope: scope_table, inner_query_name: 'ch_aggregation_inner_query' } }
  let(:lag_metric) { described_class.new(:users, :integer, nil, operation: :lag, over: :event_date) }
  let(:intersection_metric) { described_class.new(:users, :integer, nil, operation: :intersection, over: :event_date) }

  describe '.new' do
    it 'initializes with valid :lag operation' do
      expect(lag_metric.operation).to eq(:lag)
      expect(lag_metric.over_dimension).to eq(:event_date)
      expect(lag_metric.lag_offset).to eq(1)
    end

    it 'initializes with valid :intersection operation' do
      expect(intersection_metric.operation).to eq(:intersection)
    end

    it 'accepts a custom lag_offset' do
      metric = described_class.new(:users, :integer, nil, operation: :lag, over: :event_date, lag_offset: 3)

      expect(metric.lag_offset).to eq(3)
    end

    it 'raises ArgumentError for an invalid operation' do
      expect { described_class.new(:users, :integer, nil, operation: :invalid_op, over: :event_date) }
        .to raise_error(ArgumentError, /Invalid operation: invalid_op/)
    end
  end

  describe '#identifier' do
    it 'returns the name suffixed with _count as a symbol' do
      metric = described_class.new(:active_users, :integer, nil, operation: :lag, over: :event_date)

      expect(metric.identifier).to eq(:active_users_count)
    end
  end

  describe '#requires_window?' do
    it 'returns true' do
      expect(lag_metric.requires_window?).to be(true)
    end
  end

  describe '#to_inner_arel' do
    context 'when expression is provided' do
      it 'wraps the expression result in groupBitmapState' do
        metric = described_class.new(:users, :integer, -> { Arel.sql('user_id') },
          operation: :lag, over: :event_date)

        expect(metric.to_inner_arel(context).to_s).to eq('groupBitmapState(user_id)')
      end
    end

    context 'when no expression is provided' do
      it 'wraps the scope column in groupBitmapState' do
        expect(lag_metric.to_inner_arel(context).to_s).to eq('groupBitmapState(users)')
      end
    end
  end

  describe '#to_outer_arel' do
    it 'wraps the inner query column reference in groupBitmapMergeState' do
      result = lag_metric.to_outer_arel(context.merge(local_alias: 'aeq_users_count'))

      expect(result.to_s).to eq('groupBitmapMergeState(`ch_aggregation_inner_query`.`aeq_users_count`)')
    end

    it 'falls back to name when local_alias is not in context' do
      expect(lag_metric.to_outer_arel(context).to_s)
        .to eq('groupBitmapMergeState(`ch_aggregation_inner_query`.`users`)')
    end
  end

  describe '#build_window_sql' do
    context 'with :lag operation' do
      it 'generates lagInFrame SQL with default lag_offset of 1' do
        sql = lag_metric.build_window_sql(context, 'aeq_users_count', over_alias: 'aeq_event_date_daily')

        expect(sql).to eq('lagInFrame(aeq_users_count, 1, 0) OVER (ORDER BY aeq_event_date_daily ASC)')
      end

      it 'generates lagInFrame SQL with custom lag_offset' do
        metric = described_class.new(:users, :integer, nil, operation: :lag, over: :event_date, lag_offset: 2)

        sql = metric.build_window_sql(context, 'aeq_users_count', over_alias: 'aeq_event_date_daily')

        expect(sql).to eq('lagInFrame(aeq_users_count, 2, 0) OVER (ORDER BY aeq_event_date_daily ASC)')
      end
    end

    context 'with :intersection operation' do
      it 'generates arrayIntersect SQL with lagInFrame and default lag_offset of 1' do
        sql = intersection_metric.build_window_sql(context, 'aeq_users_count', over_alias: 'aeq_event_date_daily')

        expect(sql).to include('arrayIntersect(aeq_users_count,')
        expect(sql).to include('lagInFrame(aeq_users_count, 1, []) OVER (ORDER BY aeq_event_date_daily ASC)')
        expect(sql).to include('length(')
      end

      it 'generates arrayIntersect SQL with custom lag_offset' do
        metric = described_class.new(:users, :integer, nil,
          operation: :intersection, over: :event_date, lag_offset: 3)

        sql = metric.build_window_sql(context, 'aeq_users_count', over_alias: 'aeq_event_date_daily')

        expect(sql).to include('lagInFrame(aeq_users_count, 3, [])')
      end
    end
  end

  describe '#finalization_sql' do
    context 'with :lag operation' do
      it 'wraps alias in bitmapCardinality(finalizeAggregation(...))' do
        expect(lag_metric.finalization_sql('aeq_users_count'))
          .to eq('bitmapCardinality(finalizeAggregation(aeq_users_count))')
      end
    end

    context 'with :intersection operation' do
      it 'wraps alias in finalizeAggregation(...)' do
        expect(intersection_metric.finalization_sql('aeq_users_count'))
          .to eq('finalizeAggregation(aeq_users_count)')
      end
    end
  end

  describe '#validate_definition!' do
    let(:engine_class) do
      Gitlab::Database::Aggregation::ClickHouse::Engine.build do
        self.table_name = 'events'

        dimensions do
          column :event_date, :date
        end

        metrics do
          count
        end
      end
    end

    it 'does not raise when over_dimension is a registered engine dimension' do
      expect { lag_metric.validate_definition!(engine_class) }.not_to raise_error
    end

    it 'raises ArgumentError when over_dimension is not a registered engine dimension' do
      metric = described_class.new(:users, :integer, nil, operation: :lag, over: :unknown_dimension)

      expect { metric.validate_definition!(engine_class) }
        .to raise_error(ArgumentError, /references dimension 'unknown_dimension'.*not defined in the engine/)
    end
  end

  describe '#validate_part' do
    let(:matching_dimension_def) do
      instance_double(Gitlab::Database::Aggregation::ClickHouse::DimensionDefinition, name: :event_date)
    end

    let(:other_dimension_def) do
      instance_double(Gitlab::Database::Aggregation::ClickHouse::DimensionDefinition, name: :other_dimension)
    end

    let(:dimension_part) do
      instance_double(Gitlab::Database::Aggregation::QueryPlan::Dimension, definition: matching_dimension_def)
    end

    let(:other_dimension_part) do
      instance_double(Gitlab::Database::Aggregation::QueryPlan::Dimension, definition: other_dimension_def)
    end

    context 'when query plan includes the over_dimension' do
      it 'does not add errors' do
        plan = instance_double(Gitlab::Database::Aggregation::QueryPlan, dimensions: [dimension_part])
        part = instance_double(Gitlab::Database::Aggregation::QueryPlan::BasePart, query_plan: plan)

        expect(part).not_to receive(:errors)

        lag_metric.validate_part(part)
      end
    end

    context 'when query plan does not include the over_dimension' do
      it 'adds an error to the part' do
        plan = instance_double(Gitlab::Database::Aggregation::QueryPlan, dimensions: [other_dimension_part])
        errors = instance_double(ActiveModel::Errors)
        part = instance_double(Gitlab::Database::Aggregation::QueryPlan::BasePart,
          query_plan: plan, errors: errors)

        expect(errors).to receive(:add).with(
          :base,
          a_string_matching(/metric 'users_count' requires dimension 'event_date' to be requested/)
        )

        lag_metric.validate_part(part)
      end
    end
  end
end
