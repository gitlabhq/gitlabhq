# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::Engine, feature_category: :database do
  let(:engine_klass) do
    described_class.build do
      def self.metrics_mapping
        {
          count: Gitlab::Database::Aggregation::PartDefinition
        }
      end

      def self.dimensions_mapping
        {
          column: Gitlab::Database::Aggregation::PartDefinition
        }
      end

      def self.filters_mapping
        {
          column: Gitlab::Database::Aggregation::PartDefinition
        }
      end

      dimensions do
        column :user_id, :integer
      end

      filters do
        column :user_id, :integer
      end

      metrics do
        count :total_count, :integer
      end
    end
  end

  it 'requires filters_mapping definition' do
    expect(described_class).to require_method_definition(:filters_mapping)
  end

  it 'requires metrics_mapping definition' do
    expect(described_class).to require_method_definition(:metrics_mapping)
  end

  it 'requires dimensions_mapping definition' do
    expect(described_class).to require_method_definition(:dimensions_mapping)
  end

  it 'requires execute_query_plan definition' do
    expect(described_class.new(context: {})).to require_method_definition(:execute_query_plan, nil)
  end

  describe '.transient' do
    it 'stores transient expressions' do
      klass = described_class.build do
        def self.metrics_mapping
          { count: Gitlab::Database::Aggregation::PartDefinition }
        end

        def self.dimensions_mapping
          { column: Gitlab::Database::Aggregation::PartDefinition }
        end

        def self.filters_mapping
          { column: Gitlab::Database::Aggregation::PartDefinition }
        end

        transient(:duration) { 'test_expression' }
      end

      expect(klass.transients).to include(:duration)
      expect(klass.transients[:duration]).to be_a(Proc)
    end

    it 'resolves transient references in metrics via transient() helper' do
      klass = described_class.build do
        def self.metrics_mapping
          { count: Gitlab::Database::Aggregation::PartDefinition }
        end

        def self.dimensions_mapping
          { column: Gitlab::Database::Aggregation::PartDefinition }
        end

        def self.filters_mapping
          { column: Gitlab::Database::Aggregation::PartDefinition }
        end

        transient(:my_expr) { 'resolved' }

        metrics do
          count :total, :integer, transient(:my_expr)
        end
      end

      metric = klass.metrics.first
      expect(metric.expression).to be_a(Proc)
      expect(metric.expression.call).to eq('resolved')
    end

    it 'returns the stored expression when called without a block' do
      klass = described_class.build do
        def self.metrics_mapping
          { count: Gitlab::Database::Aggregation::PartDefinition }
        end

        def self.dimensions_mapping
          { column: Gitlab::Database::Aggregation::PartDefinition }
        end

        def self.filters_mapping
          { column: Gitlab::Database::Aggregation::PartDefinition }
        end

        transient(:my_expr) { 'resolved' }
      end

      expect(klass.transient(:my_expr).call).to eq('resolved')
    end
  end

  describe '.measurement' do
    def build_measurement_engine(mapping_overrides = {}, &definitions)
      mapping = {
        min: Gitlab::Database::Aggregation::ClickHouse::Min,
        max: Gitlab::Database::Aggregation::ClickHouse::Max,
        mean: Gitlab::Database::Aggregation::ClickHouse::Mean,
        quantile: Gitlab::Database::Aggregation::ClickHouse::Quantile
      }.merge(mapping_overrides).compact

      described_class.build do
        define_singleton_method(:metrics_mapping) { mapping }

        define_singleton_method(:dimensions_mapping) do
          { column: Gitlab::Database::Aggregation::PartDefinition }
        end

        define_singleton_method(:filters_mapping) do
          { column: Gitlab::Database::Aggregation::PartDefinition }
        end

        class_eval(&definitions)
      end
    end

    it 'expands into four dotted metrics' do
      engine = build_measurement_engine do
        measurement :duration, :integer, ->(_params) { Arel.sql('duration') }, description: 'Duration in seconds'
      end

      expect(engine.metrics.map(&:identifier)).to eq(
        [:"duration.min", :"duration.max", :"duration.mean", :"duration.quantile"]
      )
    end

    it 'assigns the base type to min/max and float to mean/quantile' do
      engine = build_measurement_engine do
        measurement :duration, :integer, ->(_params) { Arel.sql('duration') }
      end

      expect(engine.metrics.to_h { |m| [m.identifier, m.type] }).to eq(
        "duration.min": :integer,
        "duration.max": :integer,
        "duration.mean": :float,
        "duration.quantile": :float
      )
    end

    it 'declares a bounded quantile parameter on the quantile metric' do
      engine = build_measurement_engine do
        measurement :duration, :integer, ->(_params) { Arel.sql('duration') }
      end

      quantile = engine.metrics.find { |m| m.identifier == :"duration.quantile" }

      expect(quantile.parameters).to eq(quantile: { type: :float, in: 0.0..1.0 })
    end

    it 'derives aggregate descriptions from the measurement description' do
      engine = build_measurement_engine do
        measurement :duration, :integer, ->(_params) { Arel.sql('duration') }, description: 'Duration in seconds'
      end

      min = engine.metrics.find { |m| m.identifier == :"duration.min" }
      quantile = engine.metrics.find { |m| m.identifier == :"duration.quantile" }

      expect(min.description).to eq('Minimum duration in seconds')
      expect(quantile.description).to eq('Quantile of duration in seconds')
    end

    it 'stores the measurement in the registry' do
      engine = build_measurement_engine do
        measurement :duration, :integer, ->(_params) { Arel.sql('duration') }, description: 'Duration in seconds'
      end

      expect(engine.measurements[:duration]).to include(type: :integer, description: 'Duration in seconds')
    end

    it 'wraps zero-arity lambda expressions to accept expression params' do
      engine = build_measurement_engine do
        measurement :duration, :integer, -> { Arel.sql('duration') }
      end

      expression = engine.metrics.first.expression

      expect(expression.call({ some: :params })).to eq(Arel.sql('duration'))
    end

    it 'raises when the adapter does not support all standard aggregates' do
      expect do
        build_measurement_engine(min: nil, max: nil) do
          measurement :duration, :integer, ->(_params) { Arel.sql('duration') }
        end
      end.to raise_error(ArgumentError, /missing \[:min, :max\] in `metrics_mapping`/)
    end
  end

  describe 'duplicated definitions validation' do
    it 'raises an exception if duplicate dimensions are defined' do
      expect do
        engine_klass.dimensions do
          column :user_id, :integer
        end
      end.to raise_error("Identical engine parts found: [:user_id]. Engine parts identifiers must be unique.")
    end

    it 'raises an exception if duplicate metrics are defined' do
      expect do
        engine_klass.metrics do
          count :user_id, :integer
        end
      end.to raise_error("Identical engine parts found: [:user_id]. Engine parts identifiers must be unique.")
    end

    it 'raises an exception if duplicate filters are defined' do
      expect do
        engine_klass.filters do
          column :user_id, :integer
        end
      end.to raise_error("Identical engine parts found: [:user_id]. Engine parts identifiers must be unique.")
    end
  end

  describe 'dotted identifier guards' do
    def build_engine(&definitions)
      described_class.build do
        define_singleton_method(:metrics_mapping) do
          { metric: Gitlab::Database::Aggregation::ClickHouse::MetricDefinition }
        end

        define_singleton_method(:dimensions_mapping) do
          { column: Gitlab::Database::Aggregation::PartDefinition }
        end

        define_singleton_method(:filters_mapping) do
          { column: Gitlab::Database::Aggregation::PartDefinition }
        end

        class_eval(&definitions)
      end
    end

    it 'allows dotted metrics alongside distinct flat parts' do
      engine = build_engine do
        dimensions do
          column :user_id, :integer
        end

        metrics do
          metric :total, :integer
          metric :"duration.max", :integer, ->(_params) { Arel.sql('max(duration)') }
          metric :"duration.mean", :float, ->(_params) { Arel.sql('avg(duration)') }
        end
      end

      expect(engine.metrics.map(&:identifier)).to eq([:total, :"duration.max", :"duration.mean"])
    end

    it 'raises when identifiers collide after dot sanitization' do
      expect do
        build_engine do
          metrics do
            metric :"duration.max", :integer, ->(_params) { Arel.sql('max(duration)') }
            metric :duration__max, :integer
          end
        end
      end.to raise_error(/Identical engine part keys found: \["duration__max"\]/)
    end

    it 'raises when a dotted prefix collides with a flat identifier' do
      expect do
        build_engine do
          metrics do
            metric :duration, :integer
            metric :"duration.max", :integer, ->(_params) { Arel.sql('max(duration)') }
          end
        end
      end.to raise_error(/Dotted identifier prefixes conflict with flat identifiers: \[:duration\]/)
    end

    it 'raises for the reserved `dimensions` prefix' do
      expect do
        build_engine do
          metrics do
            metric :"dimensions.max", :integer, ->(_params) { Arel.sql('max(duration)') }
          end
        end
      end.to raise_error(/The `dimensions` prefix is reserved/)
    end
  end
end
