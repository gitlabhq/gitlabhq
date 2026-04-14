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
end
