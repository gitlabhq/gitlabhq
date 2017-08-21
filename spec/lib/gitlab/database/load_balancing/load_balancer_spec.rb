require 'spec_helper'

describe Gitlab::Database::LoadBalancing::LoadBalancer do
  let(:lb) { described_class.new(%w(localhost localhost)) }

  before do
    allow(Gitlab::Database).to receive(:create_connection_pool)
      .and_return(ActiveRecord::Base.connection_pool)
  end

  after do
    RequestStore.delete(described_class::CACHE_KEY)
  end

  describe '#read' do
    let(:conflict_error) { Class.new(RuntimeError) }

    before do
      stub_const(
        'Gitlab::Database::LoadBalancing::LoadBalancer::PG::TRSerializationFailure',
        conflict_error
      )
    end

    it 'yields a connection for a read' do
      connection = double(:connection)
      host = double(:host)

      allow(lb).to receive(:host).and_return(host)
      expect(host).to receive(:connection).and_return(connection)

      expect { |b| lb.read(&b) }.to yield_with_args(connection)
    end

    it 'marks hosts that are offline' do
      allow(lb).to receive(:connection_error?).and_return(true)

      expect(lb.host_list.hosts[0]).to receive(:offline!)
      expect(lb).to receive(:release_host)

      raised = false

      returned = lb.read do
        unless raised
          raised = true
          raise
        end

        10
      end

      expect(returned).to eq(10)
    end

    it 'retries a query in the event of a serialization failure' do
      raised = false

      expect(lb).to receive(:release_host)

      returned = lb.read do
        unless raised
          raised = true
          raise conflict_error.new
        end

        10
      end

      expect(returned).to eq(10)
    end

    it 'retries every host at most 3 times when a query conflict is raised' do
      expect(lb).to receive(:release_host).exactly(6).times
      expect(lb).to receive(:read_write)

      lb.read { raise conflict_error.new }
    end

    it 'uses the primary if no secondaries are available' do
      allow(lb).to receive(:connection_error?).and_return(true)

      lb.host_list.hosts.each do |host|
        expect(host).to receive(:online?).and_return(false)
      end

      expect(lb).to receive(:read_write).and_call_original

      expect { |b| lb.read(&b) }
        .to yield_with_args(ActiveRecord::Base.retrieve_connection)
    end
  end

  describe '#read_write' do
    it 'yields a connection for a write' do
      expect { |b| lb.read_write(&b) }
        .to yield_with_args(ActiveRecord::Base.retrieve_connection)
    end

    it 'uses a retry with exponential backoffs' do
      expect(lb).to receive(:retry_with_backoff).and_yield

      lb.read_write { 10 }
    end
  end

  describe '#host' do
    it 'returns the secondary host to use' do
      expect(lb.host).to be_an_instance_of(Gitlab::Database::LoadBalancing::Host)
    end

    it 'stores the host in a thread-local variable' do
      RequestStore.delete(described_class::CACHE_KEY)

      expect(lb.host_list).to receive(:next).once.and_call_original

      lb.host
      lb.host
    end
  end

  describe '#release_host' do
    it 'releases the host and its connection' do
      lb.host
      lb.release_host

      expect(RequestStore[described_class::CACHE_KEY]).to be_nil
    end
  end

  describe '#release_primary_connection' do
    it 'releases the connection to the primary' do
      expect(ActiveRecord::Base.connection_pool).to receive(:release_connection)

      lb.release_primary_connection
    end
  end

  describe '#primary_write_location' do
    if Gitlab::Database.postgresql?
      it 'returns a String' do
        expect(lb.primary_write_location).to be_an_instance_of(String)
      end
    end

    it 'raises an error if the write location could not be retrieved' do
      connection = double(:connection)

      allow(lb).to receive(:read_write).and_yield(connection)
      allow(connection).to receive(:select_all).and_return([])

      expect { lb.primary_write_location }.to raise_error(RuntimeError)
    end
  end

  describe '#all_caught_up?' do
    it 'returns true if all hosts caught up to the write location' do
      lb.host_list.hosts.each do |host|
        expect(host).to receive(:caught_up?).with('foo').and_return(true)
      end

      expect(lb.all_caught_up?('foo')).to eq(true)
    end

    it 'returns false if a host has not yet caught up' do
      expect(lb.host_list.hosts[0]).to receive(:caught_up?)
        .with('foo')
        .and_return(true)

      expect(lb.host_list.hosts[1]).to receive(:caught_up?)
        .with('foo')
        .and_return(false)

      expect(lb.all_caught_up?('foo')).to eq(false)
    end
  end

  describe '#retry_with_backoff' do
    it 'returns the value returned by the block' do
      value = lb.retry_with_backoff { 10 }

      expect(value).to eq(10)
    end

    it 're-raises errors not related to database connections' do
      expect(lb).not_to receive(:sleep) # to make sure we're not retrying

      expect { lb.retry_with_backoff { raise 'boop' } }
        .to raise_error(RuntimeError)
    end

    it 'retries the block when a connection error is raised' do
      allow(lb).to receive(:connection_error?).and_return(true)
      expect(lb).to receive(:sleep).with(2)
      expect(lb).to receive(:release_primary_connection)

      raised = false
      returned = lb.retry_with_backoff do
        unless raised
          raised = true
          raise
        end

        10
      end

      expect(returned).to eq(10)
    end

    it 're-raises the connection error if the retries did not succeed' do
      allow(lb).to receive(:connection_error?).and_return(true)
      expect(lb).to receive(:sleep).with(2).ordered
      expect(lb).to receive(:sleep).with(4).ordered
      expect(lb).to receive(:sleep).with(16).ordered

      expect(lb).to receive(:release_primary_connection).exactly(3).times

      expect { lb.retry_with_backoff { raise } }.to raise_error(RuntimeError)
    end
  end

  describe '#connection_error?' do
    before do
      stub_const('Gitlab::Database::LoadBalancing::LoadBalancer::CONNECTION_ERRORS',
                 [NotImplementedError])
    end

    it 'returns true for a connection error' do
      error = NotImplementedError.new

      expect(lb.connection_error?(error)).to eq(true)
    end

    it 'returns true for a wrapped connection error' do
      original = NotImplementedError.new
      wrapped = ActiveRecord::StatementInvalid.new('boop', original)

      expect(lb.connection_error?(wrapped)).to eq(true)
    end

    it 'returns true for a wrapped connection error from a view' do
      original = NotImplementedError.new
      wrapped = ActionView::Template::Error.new('boop', original)

      expect(lb.connection_error?(wrapped)).to eq(true)
    end

    it 'returns true for deeply wrapped/nested errors' do
      original = NotImplementedError.new
      middle = ActiveRecord::StatementInvalid.new('boop', original)
      top = ActionView::Template::Error.new('boop', middle)

      expect(lb.connection_error?(top)).to eq(true)
    end

    it 'returns true for an invalid encoding error' do
      error = RuntimeError.new('invalid encoding name: unicode')

      expect(lb.connection_error?(error)).to eq(true)
    end

    it 'returns false for errors not related to database connections' do
      error = RuntimeError.new

      expect(lb.connection_error?(error)).to eq(false)
    end
  end

  describe '#serialization_failure?' do
    let(:conflict_error) { Class.new(RuntimeError) }

    before do
      stub_const(
        'Gitlab::Database::LoadBalancing::LoadBalancer::PG::TRSerializationFailure',
        conflict_error
      )
    end

    it 'returns for a serialization error' do
      expect(lb.serialization_failure?(conflict_error.new)).to eq(true)
    end

    it 'returns true for a wrapped error' do
      wrapped = ActionView::Template::Error.new('boop', conflict_error.new)

      expect(lb.serialization_failure?(wrapped)).to eq(true)
    end
  end
end
