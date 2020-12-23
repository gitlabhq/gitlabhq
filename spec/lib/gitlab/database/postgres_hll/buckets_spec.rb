# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresHll::Buckets do
  let(:error_rate) { Gitlab::Database::PostgresHll::BatchDistinctCounter::ERROR_RATE } # HyperLogLog is a probabilistic algorithm, which provides estimated data, with given error margin
  let(:buckets_hash_5) { { 121 => 2, 126 => 1, 141 => 1, 383 => 1, 56 => 1 } }
  let(:buckets_hash_2) { { 141 => 1, 56 => 1 } }

  describe '#estimated_distinct_count' do
    it 'provides estimated cardinality', :aggregate_failures do
      expect(described_class.new(buckets_hash_5).estimated_distinct_count).to be_within(error_rate).percent_of(5)
      expect(described_class.new(buckets_hash_2).estimated_distinct_count).to be_within(error_rate).percent_of(2)
      expect(described_class.new({}).estimated_distinct_count).to eq 0
      expect(described_class.new.estimated_distinct_count).to eq 0
    end
  end

  describe '#merge_hash!' do
    let(:hash_a) { { 1 => 1, 2 => 3 } }
    let(:hash_b) { { 1 => 2, 2 => 1 } }

    it 'merges two hashes together into union of two sets' do
      expect(described_class.new(hash_a).merge_hash!(hash_b).to_json).to eq described_class.new(1 => 2, 2 => 3).to_json
    end
  end

  describe '#to_json' do
    it 'serialize HyperLogLog buckets as hash' do
      expect(described_class.new(1 => 5).to_json).to eq '{"1":5}'
    end
  end
end
