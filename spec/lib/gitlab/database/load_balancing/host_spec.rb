require 'spec_helper'

describe Gitlab::Database::LoadBalancing::Host do
  let(:host) { described_class.new('localhost') }

  before do
    allow(Gitlab::Database).to receive(:create_connection_pool).
      and_return(ActiveRecord::Base.connection_pool)
  end

  describe '#connection' do
    it 'returns a connection from the pool' do
      expect(host.pool).to receive(:connection)

      host.connection
    end
  end

  describe '#release_connection' do
    it 'releases the current connection from the pool' do
      expect(host.pool).to receive(:release_connection)

      host.release_connection
    end
  end

  describe '#offline!' do
    it 'marks the host as offline' do
      expect(host.pool).to receive(:disconnect!)

      host.offline!
    end
  end

  describe '#online?' do
    let(:error) { Class.new(RuntimeError) }

    before do
      allow(host.pool).to receive(:disconnect!)
    end

    it 'returns true when the host is online' do
      expect(host).not_to receive(:connection)
      expect(host).not_to receive(:release_connection)

      expect(host.online?).to eq(true)
    end

    it 'returns true when the host was marked as offline but is online again' do
      connection = double(:connection, active?: true)

      allow(host).to receive(:connection).and_return(connection)

      host.offline!

      expect(host).to receive(:release_connection)
      expect(host.online?).to eq(true)
    end

    it 'returns false when the host is offline' do
      connection = double(:connection, active?: false)

      allow(host).to receive(:connection).and_return(connection)
      expect(host).to receive(:release_connection)

      host.offline!

      expect(host.online?).to eq(false)
    end

    it 'returns false when a connection could not be established' do
      expect(host).to receive(:connection).exactly(4).times.and_raise(error)
      expect(host).to receive(:release_connection).exactly(4).times

      host.offline!

      expect(host.online?).to eq(false)
    end

    it 'retries when a connection error is thrown' do
      connection = double(:connection, active?: true)
      raised = false

      allow(host).to receive(:connection) do
        unless raised
          raised = true
          raise error.new
        end

        connection
      end

      expect(host).to receive(:release_connection).twice

      host.offline!

      expect(host.online?).to eq(true)
    end
  end

  describe '#caught_up?' do
    let(:connection) { double(:connection) }

    before do
      allow(connection).to receive(:quote).and_return('foo')
    end

    it 'returns true when a host has caught up' do
      allow(host).to receive(:connection).and_return(connection)
      expect(connection).to receive(:select_all).and_return([{ 'result' => 't' }])

      expect(host.caught_up?('foo')).to eq(true)
    end

    it 'returns false when a host has not caught up' do
      allow(host).to receive(:connection).and_return(connection)
      expect(connection).to receive(:select_all).and_return([{ 'result' => 'f' }])

      expect(host.caught_up?('foo')).to eq(false)
    end
  end
end
