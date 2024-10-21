# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::ConnectionProxy do
  let(:config) { Gitlab::Database::LoadBalancing::Configuration.new(ActiveRecord::Base) }
  let(:load_balancer) { Gitlab::Database::LoadBalancing::LoadBalancer.new(config) }
  let(:proxy) { described_class.new(load_balancer) }

  describe '#select' do
    it 'performs a read' do
      expect(proxy).to receive(:read_using_load_balancer).with(:select, 'foo')

      proxy.select('foo')
    end
  end

  describe '#select_all' do
    let(:override_proxy) { ActiveRecord::Base.connection.class }

    # We can't use :Gitlab::Utils::Override because this method is dynamically prepended
    it 'method signatures match' do
      expect(proxy.method(:select_all).parameters).to eq(override_proxy.instance_method(:select_all).parameters)
    end

    describe 'using a SELECT query' do
      it 'runs the query on a secondary' do
        arel = double(:arel)

        expect(proxy).to receive(:read_using_load_balancer)
          .with(:select_all, arel, 'foo', [])

        proxy.select_all(arel, 'foo')
      end
    end

    describe 'using a SELECT FOR UPDATE query' do
      it 'runs the query on the primary and sticks to it' do
        arel = double(:arel, locked: true)
        session = Gitlab::Database::LoadBalancing::Session.new

        allow(Gitlab::Database::LoadBalancing::SessionMap).to receive(:current).with(load_balancer)
          .and_return(session)

        expect(session).to receive(:write!)

        expect(proxy).to receive(:write_using_load_balancer)
          .with(:select_all, arel, 'foo', [])

        proxy.select_all(arel, 'foo')
      end
    end
  end

  Gitlab::Database::LoadBalancing::ConnectionProxy::NON_STICKY_READS.each do |name|
    describe name.to_s do
      it 'runs the query on the replica' do
        expect(proxy).to receive(:read_using_load_balancer)
          .with(name, 'foo')

        proxy.send(name, 'foo')
      end
    end
  end

  Gitlab::Database::LoadBalancing::ConnectionProxy::STICKY_WRITES.each do |name|
    describe name.to_s do
      it 'runs the query on the primary and sticks to it' do
        session = Gitlab::Database::LoadBalancing::Session.new

        allow(Gitlab::Database::LoadBalancing::SessionMap)
          .to receive(:current).with(load_balancer).and_return(session)

        expect(session).to receive(:write!)
        expect(proxy).to receive(:write_using_load_balancer).with(name, 'foo')

        proxy.send(name, 'foo')
      end
    end
  end

  describe 'methods using exec_insert_all on the connection', :request_store do
    let(:model_class) do
      Class.new(ApplicationRecord) do
        self.table_name = "_test_connection_proxy_insert_all"
      end
    end

    let(:session) { Gitlab::Database::LoadBalancing::Session.new }

    before do
      ActiveRecord::Schema.define do
        create_table :_test_connection_proxy_insert_all, force: true do |t|
          t.string :name, null: false
          t.index :name, unique: true
        end
      end

      allow(Gitlab::Database::LoadBalancing::SessionMap)
        .to receive(:current).with(model_class.load_balancer).and_return(session)
    end

    after do
      ActiveRecord::Schema.define do
        drop_table :_test_connection_proxy_insert_all, force: true
      end
    end

    describe '#upsert' do
      it 'upserts a record and marks the session to stick to the primary' do
        expect { 2.times { model_class.upsert({ name: 'test' }, unique_by: :name) } }
          .to change { model_class.count }.from(0).to(1)
          .and change { session.use_primary? }.from(false).to(true)
      end
    end

    describe '#insert_all!' do
      it 'inserts multiple records and marks the session to stick to the primary' do
        expect { model_class.insert_all([{ name: 'one' }, { name: 'two' }]) }
          .to change { model_class.count }.from(0).to(2)
          .and change { session.use_primary? }.from(false).to(true)
      end
    end

    describe '#insert' do
      it 'inserts a single record and marks the session to stick to the primary' do
        expect { model_class.insert({ name: 'single' }) }
          .to change { model_class.count }.from(0).to(1)
          .and change { session.use_primary? }.from(false).to(true)
      end
    end
  end

  # We have an extra test for #transaction here to make sure that nested queries
  # are also sent to a primary.
  describe '#transaction' do
    let(:session) { Gitlab::Database::LoadBalancing::Session.new }

    before do
      allow(Gitlab::Database::LoadBalancing::SessionMap)
        .to receive(:current).with(load_balancer).and_return(session)
    end

    context 'session fallbacks ambiguous queries to replicas' do
      let(:replica) { double(:connection) }

      before do
        allow(session).to receive(:fallback_to_replicas_for_ambiguous_queries?).and_return(true)
        allow(session).to receive(:use_primary?).and_return(false)
        allow(replica).to receive(:transaction).and_yield
        allow(replica).to receive(:select)
      end

      context 'with a read query' do
        it 'runs the transaction and any nested queries on the replica' do
          expect(load_balancer).to receive(:read)
            .twice.and_yield(replica)
          expect(load_balancer).not_to receive(:read_write)
          expect(session).not_to receive(:write!)

          proxy.transaction { proxy.select('true') }
        end
      end

      context 'with a write query' do
        it 'raises an exception' do
          allow(load_balancer).to receive(:read).and_yield(replica)
          allow(load_balancer).to receive(:read_write).and_yield(replica)

          expect do
            proxy.transaction { proxy.insert('something') }
          end.to raise_error(Gitlab::Database::LoadBalancing::ConnectionProxy::WriteInsideReadOnlyTransactionError)
        end
      end
    end

    context 'session does not fallback to replicas for ambiguous queries' do
      let(:primary) { double(:connection) }

      before do
        allow(session).to receive(:fallback_to_replicas_for_ambiguous_queries?).and_return(false)
        allow(session).to receive(:use_replicas_for_read_queries?).and_return(false)
        allow(session).to receive(:use_primary?).and_return(true)
        allow(primary).to receive(:transaction).and_yield
        allow(primary).to receive(:select)
        allow(primary).to receive(:insert)
      end

      context 'with a read query' do
        it 'runs the transaction and any nested queries on the primary and stick to it' do
          expect(load_balancer).to receive(:read_write)
            .twice.and_yield(primary)
          expect(load_balancer).not_to receive(:read)
          expect(session).to receive(:write!)

          proxy.transaction { proxy.select('true') }
        end
      end

      context 'with a write query' do
        it 'runs the transaction and any nested queries on the primary and stick to it' do
          expect(load_balancer).to receive(:read_write)
            .twice.and_yield(primary)
          expect(load_balancer).not_to receive(:read)
          expect(session).to receive(:write!).twice

          proxy.transaction { proxy.insert('something') }
        end
      end
    end
  end

  describe '#method_missing' do
    it 'runs the query on the primary without sticking to it' do
      expect(proxy).to receive(:write_using_load_balancer)
        .with(:foo, 'foo')

      proxy.foo('foo')
    end

    it 'properly forwards keyword arguments' do
      allow(load_balancer).to receive(:read_write)

      expect(proxy).to receive(:write_using_load_balancer).and_call_original

      expect { proxy.case_sensitive_comparison(:table, :attribute, :column, value: :value, format: :format) }
        .not_to raise_error
    end

    context 'current session prefers to fallback ambiguous queries to replicas' do
      let(:session) { double(:session) }

      before do
        allow(Gitlab::Database::LoadBalancing::SessionMap).to receive(:current).with(load_balancer)
          .and_return(session)
        allow(session).to receive(:fallback_to_replicas_for_ambiguous_queries?).and_return(true)
        allow(session).to receive(:use_primary?).and_return(false)
      end

      it 'runs the query on the replica' do
        expect(proxy).to receive(:read_using_load_balancer).with(:foo, 'foo')

        proxy.foo('foo')
      end

      it 'properly forwards keyword arguments' do
        allow(load_balancer).to receive(:read)

        expect(proxy).to receive(:read_using_load_balancer).and_call_original

        expect { proxy.case_sensitive_comparison(:table, :attribute, :column, value: :value, format: :format) }
          .not_to raise_error
      end
    end
  end

  describe '#read_using_load_balancer' do
    let(:session) { double(:session) }
    let(:connection) { double(:connection) }

    before do
      allow(Gitlab::Database::LoadBalancing::SessionMap).to receive(:current).with(load_balancer)
        .and_return(session)
    end

    context 'with a regular session' do
      it 'uses a secondary' do
        allow(session).to receive(:use_primary?).and_return(false)
        allow(session).to receive(:use_replicas_for_read_queries?).and_return(false)

        expect(connection).to receive(:foo).with('foo')
        expect(load_balancer).to receive(:read).and_yield(connection)

        proxy.read_using_load_balancer(:foo, 'foo')
      end
    end

    context 'with a regular session and forcing all reads to replicas' do
      it 'uses a secondary' do
        allow(session).to receive(:use_primary?).and_return(false)
        allow(session).to receive(:use_replicas_for_read_queries?).and_return(true)

        expect(connection).to receive(:foo).with('foo')
        expect(load_balancer).to receive(:read).and_yield(connection)

        proxy.read_using_load_balancer(:foo, 'foo')
      end
    end

    context 'with a session using the primary but forcing all reads to replicas' do
      it 'uses a secondary' do
        allow(session).to receive(:use_primary?).and_return(true)
        allow(session).to receive(:use_replicas_for_read_queries?).and_return(true)

        expect(connection).to receive(:foo).with('foo')
        expect(load_balancer).to receive(:read).and_yield(connection)

        proxy.read_using_load_balancer(:foo, 'foo')
      end
    end

    describe 'with a session using the primary' do
      it 'uses the primary' do
        allow(session).to receive(:use_primary?).and_return(true)
        allow(session).to receive(:use_replicas_for_read_queries?).and_return(false)

        expect(connection).to receive(:foo).with('foo')

        expect(load_balancer).to receive(:read_write)
          .and_yield(connection)

        proxy.read_using_load_balancer(:foo, 'foo')
      end
    end
  end

  describe '#write_using_load_balancer' do
    let(:session) { double(:session) }
    let(:connection) { double(:connection) }

    before do
      allow(Gitlab::Database::LoadBalancing::SessionMap).to receive(:current).with(load_balancer)
        .and_return(session)
    end

    it 'uses but does not stick to the primary' do
      expect(load_balancer).to receive(:read_write).and_yield(connection)
      expect(connection).to receive(:foo).with('foo')
      expect(session).not_to receive(:write!)

      proxy.write_using_load_balancer(:foo, 'foo')
    end
  end
end
