# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataQueries do
  describe '#add_metric' do
    let(:metric) { 'CountBoardsMetric' }

    it 'builds the query for given metric' do
      expect(described_class.add_metric(metric)).to eq('SELECT COUNT("boards"."id") FROM "boards"')
    end
  end

  describe '.with_metadata' do
    it 'yields passed block' do
      expect { |block| described_class.with_metadata(&block) }.to yield_with_no_args
    end
  end

  describe '.count' do
    it 'returns the raw SQL' do
      expect(described_class.count(User)).to start_with('SELECT COUNT("users"."id") FROM "users"')
    end

    it 'does not mix a nil column with keyword arguments' do
      expect(described_class.count(User, nil)).to eq('SELECT COUNT("users"."id") FROM "users"')
    end
  end

  describe '.distinct_count' do
    it 'returns the raw SQL' do
      expect(described_class.distinct_count(Issue, :author_id)).to eq('SELECT COUNT(DISTINCT "issues"."author_id") FROM "issues"')
    end

    it 'does not mix a nil column with keyword arguments' do
      expect(described_class.distinct_count(Issue, nil, start: 1, finish: 2)).to eq('SELECT COUNT(DISTINCT "issues"."id") FROM "issues"')
    end
  end

  describe '.redis_usage_data' do
    subject(:redis_usage_data) { described_class.redis_usage_data { 42 } }

    it 'returns a placeholder string for redis_usage_data with a block' do
      is_expected.to include(:redis_usage_data_block)
      expect(redis_usage_data[:redis_usage_data_block]).to eq('non-SQL usage data block')
    end
  end

  describe '.alt_usage_data' do
    subject(:alt_usage_data) { described_class.alt_usage_data { 42 } }

    it 'returns value when used with value' do
      expect(described_class.alt_usage_data(1))
        .to eq(alt_usage_data_value: 1)
    end

    it 'returns a placeholder string for alt_usage_data with a block' do
      expect(alt_usage_data[:alt_usage_data_block]).to eq('non-SQL usage data block')
    end
  end

  describe '.sum' do
    it 'returns the raw SQL' do
      expect(described_class.sum(Issue, :weight)).to eq('SELECT SUM("issues"."weight") FROM "issues"')
    end
  end

  describe '.add' do
    it 'returns the combined raw SQL with an inner query' do
      expect(described_class.add(
        'SELECT COUNT("users"."id") FROM "users"',
        'SELECT COUNT("issues"."id") FROM "issues"'
      )).to eq('SELECT (SELECT COUNT("users"."id") FROM "users") + (SELECT COUNT("issues"."id") FROM "issues")')
    end
  end

  describe '.histogram' do
    it 'returns the histogram sql' do
      expect(described_class.histogram(
        AlertManagement::HttpIntegration.active, :project_id, buckets: 1..2, bucket_size: 101
      )).to match(/^WITH "count_cte" AS MATERIALIZED/)
    end
  end

  describe 'min/max methods' do
    it 'returns nil' do
      # user min/max
      expect(described_class.minimum_id(User)).to eq(nil)
      expect(described_class.maximum_id(User)).to eq(nil)

      # issue min/max
      expect(described_class.minimum_id(Issue)).to eq(nil)
      expect(described_class.maximum_id(Issue)).to eq(nil)

      # deployment min/max
      expect(described_class.minimum_id(Deployment)).to eq(nil)
      expect(described_class.maximum_id(Deployment)).to eq(nil)

      # project min/max
      expect(described_class.minimum_id(Project)).to eq(nil)
      expect(described_class.maximum_id(Project)).to eq(nil)
    end
  end
end
