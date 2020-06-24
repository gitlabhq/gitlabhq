# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::MultiThreadedMigration do
  let(:migration) do
    Class.new { include Gitlab::Database::MultiThreadedMigration }.new
  end

  describe '#connection' do
    after do
      Thread.current[described_class::MULTI_THREAD_AR_CONNECTION] = nil
    end

    it 'returns the thread-local connection if present' do
      Thread.current[described_class::MULTI_THREAD_AR_CONNECTION] = 10

      expect(migration.connection).to eq(10)
    end

    it 'returns the global connection if no thread-local connection was set' do
      expect(migration.connection).to eq(ActiveRecord::Base.connection)
    end
  end

  describe '#with_multiple_threads' do
    it 'starts multiple threads and yields the supplied block in every thread' do
      output = Queue.new

      migration.with_multiple_threads(2) do
        output << migration.connection.execute('SELECT 1')
      end

      expect(output.size).to eq(2)
    end

    it 'joins the threads when the join parameter is set' do
      expect_any_instance_of(Thread).to receive(:join).and_call_original

      migration.with_multiple_threads(1) { }
    end
  end
end
