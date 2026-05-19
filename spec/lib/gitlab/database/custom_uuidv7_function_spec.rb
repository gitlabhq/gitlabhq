# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gen_random_uuid_v7() function', feature_category: :database do
  let(:connection) { ApplicationRecord.connection }

  describe 'output format' do
    let(:uuid) { generate(1).first }

    it 'returns a valid UUID' do
      expect(uuid).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
    end

    it 'has version nibble of 7 (RFC 9562)' do
      expect(uuid[14]).to eq('7')
    end

    it 'has RFC 4122 variant bits' do
      expect(uuid[19]).to match(/[89ab]/)
    end

    it 'encodes a current Unix ms timestamp in the first 48 bits' do
      timestamp_hex = uuid.delete('-')[0, 12]
      unix_timestamp_ms = timestamp_hex.to_i(16)

      expect(unix_timestamp_ms).to be > 0
      expect(unix_timestamp_ms).to be < (2**48)
    end
  end

  describe 'B-tree index distribution' do
    it 'produces a pg_stats correlation near 1.0' do
      connection.execute(<<~SQL)
        CREATE TEMPORARY TABLE _test_uuidv7_distribution_test (
          id uuid DEFAULT gen_random_uuid_v7() PRIMARY KEY,
          payload text
        ) ON COMMIT DROP
      SQL

      connection.execute(<<~SQL)
        INSERT INTO _test_uuidv7_distribution_test (payload)
        SELECT 'r-' || g FROM generate_series(1, 50_000) g
      SQL

      connection.execute('ANALYZE _test_uuidv7_distribution_test')

      correlation = connection.select_value(<<~SQL).to_f
        SELECT correlation FROM pg_stats
        WHERE tablename = '_test_uuidv7_distribution_test' AND attname = 'id'
      SQL

      expect(correlation).to be > 0.99
    end
  end

  describe 'consistency' do
    it 'encodes non-decreasing timestamps' do
      uuids = generate(10_000)
      timestamps = uuids.map { |u| u.delete('-')[0, 12].to_i(16) }

      decreases = timestamps.each_cons(2).count { |a, b| b < a }
      expect(decreases).to eq(0)
    end

    it 'produces unique values across 1 million generations' do
      uuids = generate(1_000_000)
      expect(uuids.uniq.size).to eq(uuids.size)
    end
  end

  describe 'function declaration' do
    it 'is declared as PARALLEL SAFE' do
      proparallel = connection.select_value(<<~SQL)
        SELECT proparallel FROM pg_proc WHERE proname = 'gen_random_uuid_v7'
      SQL

      expect(proparallel).to eq('s')
    end
  end

  def generate(series)
    connection.select_values(<<~SQL)
      SELECT gen_random_uuid_v7()::text FROM generate_series(1, #{series})
    SQL
  end
end
