# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::Sticking, :redis, :clean_gitlab_redis_db_load_balancing, feature_category: :database do
  let(:load_balancer) { ActiveRecord::Base.load_balancer }
  let(:primary_write_location) { '0/16B3A78' }
  let(:last_write_location) { '0/16B3000' }

  let(:sticking) do
    described_class.new(load_balancer)
  end

  before do
    Gitlab::Database::LoadBalancing::SessionMap.clear_session

    allow(ActiveRecord::Base.load_balancer)
      .to receive(:primary_write_location)
      .and_return(primary_write_location)
  end

  after do
    Gitlab::Database::LoadBalancing::SessionMap.clear_session
  end

  describe '#find_caught_up_replica' do
    before do
      allow(ActiveSupport::Notifications).to receive(:instrument).and_call_original
    end

    context 'when no write location could be found' do
      it 'returns true' do
        expect(load_balancer).not_to receive(:select_up_to_date_host)

        expect(sticking.find_caught_up_replica(:user, 42)).to eq(true)
      end

      context 'when use_primary_on_empty_location is true' do
        it 'returns false and calls use_primary!' do
          expect(load_balancer).not_to receive(:select_up_to_date_host)
          expect(::Gitlab::Database::LoadBalancing::SessionMap.current(load_balancer)).to receive(:use_primary!)

          expect(sticking.find_caught_up_replica(:user, 42, use_primary_on_empty_location: true)).to eq(false)
        end
      end
    end

    context 'when all replicas have caught up' do
      before do
        Gitlab::Redis::DbLoadBalancing.with do |redis|
          redis.set("database-load-balancing/write-location/#{load_balancer.name}/user/42", last_write_location, ex: 30)
        end
      end

      it 'returns true and unsticks if location matches' do
        expect(load_balancer).to receive(:select_up_to_date_host).with(last_write_location)
          .and_return(::Gitlab::Database::LoadBalancing::LoadBalancer::ALL_CAUGHT_UP)
        expect(::Gitlab::Database::LoadBalancing::SessionMap.current(load_balancer)).not_to receive(:use_primary!)

        expect(sticking.find_caught_up_replica(:user, 42)).to eq(true)

        # Verify the sticking point was removed
        Gitlab::Redis::DbLoadBalancing.with do |redis|
          expect(redis.get("database-load-balancing/write-location/#{load_balancer.name}/user/42")).to be_nil
        end
      end

      context 'when the sticking point has changed (concurrent write)' do
        it 'returns true but does not unstick' do
          expect(load_balancer).to receive(:select_up_to_date_host)
            .with(last_write_location).and_wrap_original do |method, location|
              # Change the sticking point while select_up_to_date_host is being called
              new_location = '0/16B4000'
              Gitlab::Redis::DbLoadBalancing.with do |redis|
                redis.set("database-load-balancing/write-location/#{load_balancer.name}/user/42", new_location, ex: 30)
              end
              method.call(location)
            end
          expect(::Gitlab::Database::LoadBalancing::SessionMap.current(load_balancer)).not_to receive(:use_primary!)

          expect(sticking.find_caught_up_replica(:user, 42)).to eq(true)

          # Verify the sticking point was NOT removed (it changed)
          Gitlab::Redis::DbLoadBalancing.with do |redis|
            expect(redis.get("database-load-balancing/write-location/#{load_balancer.name}/user/42")).to eq("0/16B4000")
          end
        end
      end
    end

    context 'when only some of the replicas have caught up' do
      before do
        Gitlab::Redis::DbLoadBalancing.with do |redis|
          redis.set("database-load-balancing/write-location/#{load_balancer.name}/user/42", last_write_location, ex: 30)
        end
      end

      it 'returns true and does not unstick' do
        expect(load_balancer).to receive(:select_up_to_date_host).with(last_write_location)
          .and_return(::Gitlab::Database::LoadBalancing::LoadBalancer::ANY_CAUGHT_UP)

        expect(sticking.find_caught_up_replica(:user, 42)).to eq(true)

        # Verify the sticking point was NOT removed
        Gitlab::Redis::DbLoadBalancing.with do |redis|
          expect(redis.get("database-load-balancing/write-location/#{load_balancer.name}/user/42"))
            .to eq(last_write_location)
        end
      end
    end

    context 'when none of the replicas have caught up' do
      before do
        Gitlab::Redis::DbLoadBalancing.with do |redis|
          redis.set("database-load-balancing/write-location/#{load_balancer.name}/user/42", last_write_location, ex: 30)
        end

        allow(load_balancer).to receive(:select_up_to_date_host).with(last_write_location)
          .and_return(::Gitlab::Database::LoadBalancing::LoadBalancer::NONE_CAUGHT_UP)
      end

      it 'returns false and calls use_primary!' do
        expect(::Gitlab::Database::LoadBalancing::SessionMap.current(load_balancer)).to receive(:use_primary!)

        expect(sticking.find_caught_up_replica(:user, 42)).to eq(false)
      end

      context 'when use_primary_on_failure is false' do
        it 'does not call use_primary!' do
          expect(::Gitlab::Database::LoadBalancing::SessionMap.current(load_balancer)).not_to receive(:use_primary!)

          expect(sticking.find_caught_up_replica(:user, 42, use_primary_on_failure: false)).to eq(false)
        end
      end
    end
  end

  shared_examples 'sticking' do
    let(:hash_id) { false }

    context 'when replicas are used' do
      before do
        allow(ActiveRecord::Base.load_balancer)
          .to receive(:primary_only?)
          .and_return(false)

        stub_feature_flags(db_load_balancing_atomic_sticking: false)
      end

      it 'sticks an entity to the primary', :aggregate_failures do
        expect(Gitlab::Database::LoadBalancing::SessionMap.current(load_balancer)).to receive(:use_primary!)

        subject

        ids.each do |id|
          Gitlab::Redis::DbLoadBalancing.with do |redis|
            expect(redis.get("database-load-balancing/write-location/#{load_balancer.name}/user/#{id}"))
              .to eq(primary_write_location)
          end
        end
      end

      context 'with hash_id: true' do
        let(:hash_id) { true }

        it 'sticks a hash instead of the actual id' do
          subject

          ids.each do |id|
            hashed_id = Digest::SHA256.hexdigest(id.to_s)

            Gitlab::Redis::DbLoadBalancing.with do |redis|
              expect(redis.get("database-load-balancing/write-location/#{load_balancer.name}/user/#{hashed_id}"))
                .to eq(primary_write_location)
            end
          end
        end
      end
    end

    context 'when replicas are not used' do
      it 'does not update the write location when no replicas are used' do
        expect(sticking).not_to receive(:set_write_location_for)

        subject
      end
    end
  end

  describe '#stick' do
    it_behaves_like 'sticking' do
      let(:ids) { [42] }
      subject { sticking.stick(:user, ids.first, hash_id: hash_id) }
    end
  end

  describe '#bulk_stick' do
    it_behaves_like 'sticking' do
      let(:ids) { [42, 43] }
      subject { sticking.bulk_stick(:user, ids, hash_id: hash_id) }
    end
  end

  describe '#set_write_location_for' do
    let(:redis_key) { "database-load-balancing/write-location/#{load_balancer.name}/user/42" }

    before do
      allow(ActiveRecord::Base.load_balancer)
        .to receive(:primary_only?)
        .and_return(false)
    end

    context 'when feature flag is enabled' do
      before do
        stub_feature_flags(db_load_balancing_atomic_sticking: true)
      end

      it 'uses atomic set_write_location_for' do
        expect(sticking).to receive(:set_atomic_write_location_for).with(:user, 42, primary_write_location)
                                                                   .and_call_original

        sticking.stick(:user, 42)

        Gitlab::Redis::DbLoadBalancing.with do |redis|
          expect(redis.get("database-load-balancing/write-location/#{load_balancer.name}/user/42"))
            .to eq(primary_write_location)
        end
      end
    end

    context 'when feature flag is disabled (default)' do
      before do
        stub_feature_flags(db_load_balancing_atomic_sticking: false)
      end

      it 'uses regular redis set' do
        expect(sticking).not_to receive(:set_atomic_write_location_for)

        sticking.stick(:user, 42)

        Gitlab::Redis::DbLoadBalancing.with do |redis|
          expect(redis.get("database-load-balancing/write-location/#{load_balancer.name}/user/42"))
              .to eq(primary_write_location)
        end
      end
    end
  end

  describe '#set_atomic_write_location_for' do
    let(:redis_key) { "database-load-balancing/write-location/#{load_balancer.name}/user/42" }

    before do
      allow(ActiveRecord::Base.load_balancer)
        .to receive(:primary_only?)
        .and_return(false)

      stub_feature_flags(db_load_balancing_atomic_sticking: true)
    end

    context 'when no existing LSN is stored' do
      it 'stores the new LSN and returns 1' do
        result = sticking.send(:set_atomic_write_location_for, :user, 42, '0/2000')

        expect(result).to eq(1)

        Gitlab::Redis::DbLoadBalancing.with do |redis|
          expect(redis.get(redis_key)).to eq('0/2000')
        end
      end
    end

    context 'when new LSN is higher than current' do
      before do
        Gitlab::Redis::DbLoadBalancing.with do |redis|
          redis.set(redis_key, '0/1000', ex: 30)
        end
      end

      it 'updates to the new LSN and returns 1' do
        result = sticking.send(:set_atomic_write_location_for, :user, 42, '0/2000')

        expect(result).to eq(1)

        Gitlab::Redis::DbLoadBalancing.with do |redis|
          expect(redis.get(redis_key)).to eq('0/2000')
        end
      end
    end

    context 'when the new LSN is lower than current' do
      before do
        Gitlab::Redis::DbLoadBalancing.with do |redis|
          redis.set(redis_key, '0/3000', ex: 30)
        end
      end

      it 'keeps the current LSN and returns 0' do
        result = sticking.send(:set_atomic_write_location_for, :user, 42, '0/2000')

        expect(result).to eq(0)

        Gitlab::Redis::DbLoadBalancing.with do |redis|
          expect(redis.get(redis_key)).to eq('0/3000')
        end
      end

      it 'refreshes the TTL' do
        Gitlab::Redis::DbLoadBalancing.with do |redis|
          redis.set(redis_key, '0/3000', ex: 5)
          initial_ttl = redis.ttl(redis_key)

          sticking.send(:set_atomic_write_location_for, :user, 42, '0/2000')

          new_ttl = redis.ttl(redis_key)
          expect(new_ttl).to be > initial_ttl
          expect(new_ttl).to be <= described_class::EXPIRATION
        end
      end
    end

    context 'when LSN equals to the current' do
      before do
        Gitlab::Redis::DbLoadBalancing.with do |redis|
          redis.set(redis_key, '0/2000', ex: 30)
        end
      end

      it 'keeps the current LSN and returns 0' do
        result = sticking.send(:set_atomic_write_location_for, :user, 42, '0/2000')

        expect(result).to eq(0)

        Gitlab::Redis::DbLoadBalancing.with do |redis|
          expect(redis.get(redis_key)).to eq('0/2000')
        end
      end
    end

    context 'when LSN format is invalid' do
      it 'returns an error for invalid format' do
        expect do
          sticking.send(:set_atomic_write_location_for, :user, 42, 'invalid-lsn')
        end.to raise_error(Redis::CommandError, /ERR ARGV\[1\] must be a valid LSN/)
      end
    end

    context 'with maximum possible LSN values' do
      it 'correctly distinguishes maximum LSN values differing by 1' do
        Gitlab::Redis::DbLoadBalancing.with do |redis|
          redis.set(redis_key, 'FFFFFFFF/FFFFFFFE', ex: 30)
        end

        result = sticking.send(:set_atomic_write_location_for, :user, 42, 'FFFFFFFF/FFFFFFFF')

        expect(result).to eq(1)

        Gitlab::Redis::DbLoadBalancing.with do |redis|
          expect(redis.get(redis_key)).to eq('FFFFFFFF/FFFFFFFF')
        end
      end
    end

    context 'when TTL is invalid' do
      it 'returns an error for non-positive TTL' do
        stub_const("#{described_class}::EXPIRATION", 0)

        expect do
          sticking.send(:set_atomic_write_location_for, :user, 42, '0/2000')
        end.to raise_error(Redis::CommandError, /ERR ARGV\[2\] \(TTL\) must be a positive integer/)
      end
    end
  end
end
