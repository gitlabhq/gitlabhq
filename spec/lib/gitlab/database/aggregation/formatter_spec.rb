# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::Formatter, feature_category: :database do
  subject(:formatter) { described_class.new(engine, plan) }

  let(:engine) do
    Gitlab::Database::Aggregation::Engine.build do
      def self.metrics_mapping
        {
          count: Gitlab::Database::Aggregation::PartDefinition
        }
      end

      metrics do
        count :total_count, :integer
        count :total_with_formatting_count, :integer, nil, formatter: ->(v) { v * -1 }
      end
    end
  end

  let(:plan) { Gitlab::Database::Aggregation::QueryPlan.build(request, engine.new(context: {})) }
  let(:request) do
    Gitlab::Database::Aggregation::Request.new(metrics: [{ identifier: :total_count },
      { identifier: :total_with_formatting_count }])
  end

  describe '#format_data' do
    it 'applies formatting procs on columns with proc defined' do
      expect(formatter.format_data([{ 'total_with_formatting_count' => 4, 'total_count' => 3 }]))
      .to eq([{ 'total_with_formatting_count' => -4, 'total_count' => 3 }])
    end

    it 'leaves unknown data untouched' do
      expect(formatter.format_data([{ 'dummy' => 3 }]))
            .to eq([{ 'dummy' => 3 }])
    end
  end
end
