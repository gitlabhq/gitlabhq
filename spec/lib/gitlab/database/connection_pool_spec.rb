require 'spec_helper'

describe Gitlab::Database::ConnectionPool, lib: true do
  let(:pool_size) { 1 }
  let(:subject) { described_class.new(pool_size) }

  after do
    subject.close
  end

  describe '.with_pool' do
    let(:pool_size) { 123 }

    it 'creates and passes a pool and join and close it after done' do
      used_pool = described_class.with_pool(pool_size) do |pool|
        expect(pool).to be_kind_of(described_class)
        expect(pool).to receive(:join).and_call_original
        expect(pool.pool_size).to eq(pool_size)

        pool.execute_async('SELECT 1;')

        pool
      end

      expect(used_pool).to be_closed
    end

    it 'tries to join and close the pool even if there is an error' do
      error = Class.new(RuntimeError)

      begin
        described_class.with_pool(pool_size) do |pool|
          expect(pool).to receive(:join).and_call_original
          expect(pool).to receive(:close).and_call_original

          pool.execute_async('SELECT 1;')

          raise error.new('boom')
        end
      rescue error
      end
    end
  end

  describe '#pool_size' do
    let(:pool_size) { 123 }

    it 'returns correct pool size' do
      expect(subject.pool_size).to eq(pool_size)
    end
  end

  describe '#execute_async' do
    it 'runs the right query' do
      subject.execute_async('SELECT 1+2 AS value;', method: :exec_query)
      result = convert_result_to_hash(subject.join)

      expect(result).to eq([[{ 'value' => 3 }]])
    end
  end

  describe '#join' do
    before do
      2.times.map do |n|
        subject.execute_async("SELECT #{n} AS value;", method: :exec_query)
      end
    end

    it 'joins the threads and give respective values, and clear workers' do
      result = convert_result_to_hash(subject.join)

      expected = 2.times.map do |n|
        [{ 'value' => n }]
      end

      expect(result).to eq(expected)
      expect(subject.workers).to be_empty
    end
  end

  describe '#close and #closed?' do
    before do
      subject.execute_async('SELECT 1;')
      subject.join
    end

    it 'disconnects the connection pool after closed' do
      expect(subject).not_to be_closed

      subject.close

      expect(subject).to be_closed
    end
  end

  def convert_result_to_hash(values)
    values.map do |result|
      result.map do |row|
        ActiveRecord::AttributeSet::Builder.new({})
          .build_from_database(row, result.column_types).to_h
      end
    end
  end
end
