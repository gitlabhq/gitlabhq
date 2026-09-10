# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::TierDimension, :click_house, feature_category: :database do
  include ClickHouseHelpers

  let(:engine_definition) do
    Gitlab::Database::Aggregation::ClickHouse::Engine.build do
      self.table_name = 'duo_workflows_workflows_enriched'

      dimensions do
        tier :credits_tier, :string, -> { sql('credits_used') }
      end

      metrics do
        count
      end
    end
  end

  let(:engine) do
    engine_definition.new(
      context: { scope: ClickHouse::Client::QueryBuilder.new('duo_workflows_workflows_enriched') }
    )
  end

  before do
    clickhouse_fixture(:duo_workflows_workflows_enriched, [
      flow_row(id: 1, credits: 0.0),
      flow_row(id: 2, credits: 4.9),
      flow_row(id: 3, credits: 5.0),  # == first threshold, goes to the upper tier
      flow_row(id: 4, credits: 20.0),
      flow_row(id: 5, credits: 25.0)  # == last threshold, goes to the highest tier
    ])
  end

  def flow_row(id:, credits:)
    {
      id: id,
      user_id: id,
      traversal_path: '1/2/',
      created_at: datetime64('2025-03-01 00:00:00'),
      credits_used: credits,
      _siphon_deleted: false,
      _version: datetime64('2025-03-01 00:00:00')
    }
  end

  def datetime64(value)
    Arel.sql("parseDateTime64BestEffort('#{value}', 6, 'UTC')")
  end

  def request_for(parameters, order: true)
    Gitlab::Database::Aggregation::Request.new(
      dimensions: [{ identifier: :credits_tier, parameters: parameters }],
      metrics: [{ identifier: :total_count }],
      order: order ? [{ identifier: :credits_tier, parameters: parameters, direction: :asc }] : []
    )
  end

  it 'buckets values into ordinal tiers starting at tier_0, boundaries going to the upper tier' do
    expect(engine).to execute_aggregation(request_for({ thresholds: [5, 25] })).and_return([
      { credits_tier_5_25: 'tier_0', total_count: 2 },
      { credits_tier_5_25: 'tier_1', total_count: 2 },
      { credits_tier_5_25: 'tier_2', total_count: 1 }
    ])
  end

  it 'accepts the maximum of 9 thresholds, keeping tier labels single-digit' do
    instance_key = :"credits_tier_#{(1..9).to_a.join('_')}"

    expect(engine).to execute_aggregation(request_for({ thresholds: (1..9).to_a })).and_return([
      { instance_key => 'tier_0', total_count: 1 },
      { instance_key => 'tier_4', total_count: 1 },
      { instance_key => 'tier_5', total_count: 1 },
      { instance_key => 'tier_9', total_count: 2 }
    ])
  end

  it 'fails validation when thresholds are missing' do
    expect(engine).to execute_aggregation(request_for({}, order: false)).with_errors([
      a_string_matching(/parameter `thresholds` is required/)
    ])
  end

  it 'fails validation when thresholds are not ascending' do
    expect(engine).to execute_aggregation(request_for({ thresholds: [25, 5] }, order: false)).with_errors([
      a_string_matching(/parameter `thresholds` must be strictly ascending positive integers/)
    ])
  end

  it 'fails validation when a threshold is not a positive integer' do
    expect(engine).to execute_aggregation(request_for({ thresholds: [0, 5] }, order: false)).with_errors([
      a_string_matching(/parameter `thresholds` must be strictly ascending positive integers/)
    ])
  end

  it 'fails validation when a threshold is not an integer' do
    expect(engine).to execute_aggregation(request_for({ thresholds: [1, 2.5] }, order: false)).with_errors([
      a_string_matching(/parameter `thresholds` must be strictly ascending positive integers/)
    ])
  end

  it 'fails validation when more than 9 thresholds are given' do
    expect(engine).to execute_aggregation(request_for({ thresholds: (1..10).to_a }, order: false)).with_errors([
      a_string_matching(/parameter `thresholds` supports at most 9 values/)
    ])
  end
end
