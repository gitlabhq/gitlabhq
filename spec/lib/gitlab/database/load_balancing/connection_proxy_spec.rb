require 'spec_helper'

describe Gitlab::Database::LoadBalancing::ConnectionProxy do
  let(:proxy) { described_class.new }

  describe '#select' do
    it 'performs a read' do
      expect(proxy).to receive(:read_using_load_balancer).with(:select, ['foo'])

      proxy.select('foo')
    end
  end

  describe '#select_all' do
    describe 'using a SELECT query' do
      it 'runs the query on a secondary' do
        arel = double(:arel)

        expect(proxy).to receive(:read_using_load_balancer)
          .with(:select_all, [arel, 'foo', []])

        proxy.select_all(arel, 'foo')
      end
    end

    describe 'using a SELECT FOR UPDATE query' do
      it 'runs the query on the primary and sticks to it' do
        arel = double(:arel, locked: true)

        expect(proxy).to receive(:write_using_load_balancer)
          .with(:select_all, [arel, 'foo', []], sticky: true)

        proxy.select_all(arel, 'foo')
      end
    end
  end

  Gitlab::Database::LoadBalancing::ConnectionProxy::STICKY_WRITES.each do |name|
    describe "#{name}" do
      it 'runs the query on the primary and sticks to it' do
        expect(proxy).to receive(:write_using_load_balancer)
          .with(name, ['foo'], sticky: true)

        proxy.send(name, 'foo')
      end
    end
  end

  # We have an extra test for #transaction here to make sure that nested queries
  # are also sent to a primary.
  describe '#transaction' do
    after do
      Gitlab::Database::LoadBalancing::Session.clear_session
    end

    it 'runs the transaction and any nested queries on the primary' do
      primary = double(:connection)

      allow(primary).to receive(:transaction).and_yield
      allow(primary).to receive(:select)

      expect(proxy.load_balancer).to receive(:read_write)
        .twice.and_yield(primary)

      # This expectation is put in place to ensure no read is performed.
      expect(proxy.load_balancer).not_to receive(:read)

      proxy.transaction { proxy.select('true') }

      expect(Gitlab::Database::LoadBalancing::Session.current.use_primary?)
        .to eq(true)
    end
  end

  describe '#method_missing' do
    it 'runs the query on the primary without sticking to it' do
      expect(proxy).to receive(:write_using_load_balancer)
        .with(:foo, ['foo'])

      proxy.foo('foo')
    end

    it 'properly forwards trailing hash arguments' do
      allow(proxy.load_balancer).to receive(:read_write)

      expect(proxy).to receive(:write_using_load_balancer).and_call_original

      expect { proxy.case_sensitive_comparison(:table, :attribute, :column, { value: :value, format: :format }) }
        .not_to raise_error
    end
  end

  describe '#read_using_load_balancer' do
    let(:session) { double(:session) }
    let(:connection) { double(:connection) }

    before do
      allow(Gitlab::Database::LoadBalancing::Session).to receive(:current)
        .and_return(session)
    end

    describe 'with a regular session' do
      it 'uses a secondary' do
        allow(session).to receive(:use_primary?).and_return(false)

        expect(connection).to receive(:foo).with('foo')
        expect(proxy.load_balancer).to receive(:read).and_yield(connection)

        proxy.read_using_load_balancer(:foo, ['foo'])
      end
    end

    describe 'with a session using the primary' do
      it 'uses the primary' do
        allow(session).to receive(:use_primary?).and_return(true)

        expect(connection).to receive(:foo).with('foo')

        expect(proxy.load_balancer).to receive(:read_write)
          .and_yield(connection)

        proxy.read_using_load_balancer(:foo, ['foo'])
      end
    end
  end

  describe '#write_using_load_balancer' do
    let(:session) { double(:session) }
    let(:connection) { double(:connection) }

    before do
      allow(Gitlab::Database::LoadBalancing::Session).to receive(:current)
        .and_return(session)
    end

    it 'it uses but does not stick to the primary when sticking is disabled' do
      expect(proxy.load_balancer).to receive(:read_write).and_yield(connection)
      expect(connection).to receive(:foo).with('foo')
      expect(session).not_to receive(:write!)

      proxy.write_using_load_balancer(:foo, ['foo'])
    end

    it 'sticks to the primary when sticking is enabled' do
      expect(proxy.load_balancer).to receive(:read_write).and_yield(connection)
      expect(connection).to receive(:foo).with('foo')
      expect(session).to receive(:write!)

      proxy.write_using_load_balancer(:foo, ['foo'], sticky: true)
    end
  end
end
