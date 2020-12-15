# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresqlAdapter::EmptyQueryPing do
  describe '#active?' do
    let(:adapter_class) do
      Class.new do
        include Gitlab::Database::PostgresqlAdapter::EmptyQueryPing

        def initialize(connection, lock)
          @connection = connection
          @lock = lock
        end
      end
    end

    subject { adapter_class.new(connection, lock).active? }

    let(:connection) { double(query: nil) }
    let(:lock) { double }

    before do
      allow(lock).to receive(:synchronize).and_yield
    end

    it 'uses an empty query to check liveness' do
      expect(connection).to receive(:query).with(';')

      subject
    end

    it 'returns true if no error was signaled' do
      expect(subject).to be_truthy
    end

    it 'returns false when an error occurs' do
      expect(lock).to receive(:synchronize).and_raise(PG::Error)

      expect(subject).to be_falsey
    end
  end
end
