# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::MetricFilterDefinition, feature_category: :database do
  it 'requires #apply_outer definition' do
    expect(described_class.new(:foo, :bar)).to require_method_definition(:apply_outer, nil, nil, nil)
  end

  describe '#metric?' do
    it 'returns true' do
      expect(described_class.new(:total_count, :integer).metric?).to be(true)
    end
  end

  describe '#validate_definition!' do
    let(:engine_class) do
      Gitlab::Database::Aggregation::ClickHouse::Engine.build do
        self.table_name = 'events'

        dimensions do
          column :user_id, :integer
        end

        metrics do
          count
        end
      end
    end

    it 'does not raise when a metric with the same identifier is registered' do
      filter = described_class.new(:total_count, :integer)

      expect { filter.validate_definition!(engine_class) }.not_to raise_error
    end

    it 'raises ArgumentError when no metric with the same identifier is registered' do
      filter = described_class.new(:unknown_count, :integer)

      expect { filter.validate_definition!(engine_class) }
        .to raise_error(ArgumentError, /MetricFilter 'unknown_count'.*not defined in the engine/)
    end
  end
end
