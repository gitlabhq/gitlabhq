require 'spec_helper'

describe Gitlab::Database::LoadBalancing::RackMiddleware, :redis do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }

  after do
    Gitlab::Database::LoadBalancing::Session.clear_session
  end

  describe '#call' do
    let(:lb) { double(:lb) }
    let(:user) { double(:user, id: 42) }

    before do
      expect(app).to receive(:call).with(an_instance_of(Hash))

      allow(middleware).to receive(:load_balancer).and_return(lb)

      expect(middleware).to receive(:clear).twice
    end

    context 'when the primary was used' do
      it 'assigns the user to the primary' do
        allow(middleware).to receive(:user_for_request).and_return(user)

        allow(middleware).to receive(:last_write_location_for).
          with(user).
          and_return('123')

        allow(lb).to receive(:all_caught_up?).with('123').and_return(false)

        expect(middleware).to receive(:assign_primary_for_user).with(user)

        middleware.call({})
      end
    end

    context 'when a primary was not used' do
      it 'does not assign the user to the primary' do
        allow(middleware).to receive(:user_for_request).and_return(user)

        allow(middleware).to receive(:last_write_location_for).
          with(user).
          and_return('123')

        allow(lb).to receive(:all_caught_up?).with('123').and_return(true)

        expect(middleware).not_to receive(:assign_primary_for_user)

        middleware.call({})
      end
    end
  end

  describe '#check_primary_requirement' do
    let(:lb) { double(:lb) }
    let(:user) { double(:user, id: 42) }

    before do
      allow(middleware).to receive(:load_balancer).and_return(lb)
    end

    it 'marks the primary as the host to use when necessary' do
      expect(middleware).to receive(:last_write_location_for).
        with(user).
        and_return('foo')

      expect(lb).to receive(:all_caught_up?).with('foo').and_return(false)

      expect(Gitlab::Database::LoadBalancing::Session.current).
        to receive(:use_primary!)

      middleware.check_primary_requirement(user)
    end

    it 'does not use the primary when there is no cached write location' do
      expect(middleware).to receive(:last_write_location_for).
        with(user).
        and_return(nil)

      expect(lb).not_to receive(:all_caught_up?)

      expect(Gitlab::Database::LoadBalancing::Session.current).
        not_to receive(:use_primary!)

      middleware.check_primary_requirement(user)
    end

    it 'does not use the primary when all hosts have caught up' do
      expect(middleware).to receive(:last_write_location_for).
        with(user).
        and_return('foo')

      expect(lb).to receive(:all_caught_up?).with('foo').and_return(true)

      expect(middleware).to receive(:delete_write_location_for).with(user)

      middleware.check_primary_requirement(user)
    end
  end

  describe '#assign_primary_for_user' do
    it 'stores primary instance details for the current user' do
      user = double(:user, id: 42)

      lb = double(:load_balancer, primary_write_location: '123')

      allow(middleware).to receive(:load_balancer).and_return(lb)

      expect(middleware).to receive(:set_write_location_for).with(user, '123')

      middleware.assign_primary_for_user(user)
    end
  end

  describe '#clear' do
    it 'clears the currently used host and session' do
      proxy = double(:proxy)
      lb = double(:lb)

      allow(Gitlab::Database::LoadBalancing).to receive(:proxy).and_return(proxy)
      allow(proxy).to receive(:load_balancer).and_return(lb)
      expect(lb).to receive(:release_host)

      middleware.clear

      thread_key = Gitlab::Database::LoadBalancing::Session::CACHE_KEY

      expect(RequestStore[thread_key]).to be_nil
    end
  end

  describe '#load_balancer' do
    it 'returns the load balancer' do
      proxy = double(:proxy)

      allow(Gitlab::Database::LoadBalancing).to receive(:proxy).and_return(proxy)

      expect(proxy).to receive(:load_balancer)

      middleware.load_balancer
    end
  end

  describe '#user_for_request' do
    let(:user) { double(:user, id: 42) }

    it 'returns the current user for a Grape request' do
      env = { 'api.endpoint' => double(:api, current_user: user) }

      expect(middleware.user_for_request(env)).to eq(user)
    end

    it 'returns the current user for a Rails request' do
      env = { 'warden' => double(:warden, user: user) }

      expect(middleware.user_for_request(env)).to eq(user)
    end

    it 'returns nil if no user could be found' do
      expect(middleware.user_for_request({})).to be_nil
    end
  end

  describe '#last_write_location_for' do
    it 'returns the last WAL write location for a user' do
      user = double(:user, id: 42)

      middleware.set_write_location_for(user, '123')

      expect(middleware.last_write_location_for(user)).to eq('123')
    end
  end

  describe '#delete_write_location' do
    it 'removes the WAL write location from Redis' do
      user = double(:user, id: 42)

      middleware.set_write_location_for(user, '123')
      middleware.delete_write_location_for(user)

      expect(middleware.last_write_location_for(user)).to be_nil
    end
  end

  describe '#set_write_location' do
    it 'stores the WAL write location in Redis' do
      user = double(:user, id: 42)

      middleware.set_write_location_for(user, '123')

      expect(middleware.last_write_location_for(user)).to eq('123')
    end
  end

  describe '#redis_key_for' do
    it 'returns a String' do
      user = double(:user, id: 42)

      expect(middleware.redis_key_for(user)).
        to eq('database-load-balancing/write-location/42')
    end
  end
end
