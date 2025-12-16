# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::Engine, feature_category: :database do
  it 'requires metrics_mapping definition' do
    expect(described_class).to require_method_definition(:metrics_mapping)
  end

  it 'requires dimensions_mapping definition' do
    expect(described_class).to require_method_definition(:dimensions_mapping)
  end

  it 'requires execute_query_plan definition' do
    expect(described_class.new(context: {})).to require_method_definition(:execute_query_plan, nil)
  end

  describe 'duplicates validation' do
    let(:engine_klass) do
      Gitlab::Database::Aggregation::Engine.build do
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

        dimensions do
          column :user_id, :integer
        end
      end
    end

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
  end
end
