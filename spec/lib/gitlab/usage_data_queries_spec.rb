# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataQueries do
  before do
    allow(ActiveRecord::Base.connection).to receive(:transaction_open?).and_return(false)
  end

  describe '.count' do
    it 'returns the raw SQL' do
      expect(described_class.count(User)).to start_with('SELECT COUNT("users"."id") FROM "users"')
    end
  end

  describe '.distinct_count' do
    it 'returns the raw SQL' do
      expect(described_class.distinct_count(Issue, :author_id)).to eq('SELECT COUNT(DISTINCT "issues"."author_id") FROM "issues"')
    end
  end

  describe '.redis_usage_data' do
    subject(:redis_usage_data) { described_class.redis_usage_data { 42 } }

    it 'returns a class for redis_usage_data with a counter call' do
      expect(described_class.redis_usage_data(Gitlab::UsageDataCounters::WikiPageCounter))
        .to eq(redis_usage_data_counter: Gitlab::UsageDataCounters::WikiPageCounter)
    end

    it 'returns a stringified block for redis_usage_data with a block' do
      is_expected.to include(:redis_usage_data_block)
      expect(redis_usage_data[:redis_usage_data_block]).to start_with('#<Proc:')
    end
  end

  describe '.sum' do
    it 'returns the raw SQL' do
      expect(described_class.sum(Issue, :weight)).to eq('SELECT SUM("issues"."weight") FROM "issues"')
    end
  end
end
