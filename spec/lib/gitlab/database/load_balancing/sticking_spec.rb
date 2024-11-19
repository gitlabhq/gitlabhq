# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::Sticking, :redis do
  let(:load_balancer) { ActiveRecord::Base.load_balancer }
  let(:primary_write_location) { 'the-primary-lsn' }
  let(:last_write_location) { 'the-last-write-lsn' }

  let(:sticking) do
    described_class.new(load_balancer)
  end

  let(:redis) { instance_double(::Gitlab::Redis::MultiStore) }

  before do
    Gitlab::Database::LoadBalancing::SessionMap.clear_session
    allow(::Gitlab::Redis::DbLoadBalancing).to receive(:with).and_yield(redis)

    allow(ActiveRecord::Base.load_balancer)
      .to receive(:primary_write_location)
      .and_return(primary_write_location)

    allow(redis).to receive(:get)
      .with("database-load-balancing/write-location/#{load_balancer.name}/user/42")
      .and_return(last_write_location)
  end

  after do
    Gitlab::Database::LoadBalancing::SessionMap.clear_session
  end

  describe '#find_caught_up_replica' do
    before do
      allow(ActiveSupport::Notifications).to receive(:instrument).and_call_original
    end

    context 'when no write location could be found' do
      let(:last_write_location) { nil }

      it 'returns true' do
        expect(load_balancer).not_to receive(:select_up_to_date_host)

        expect(sticking.find_caught_up_replica(:user, 42)).to eq(true)
      end

      context 'when use_primary_on_empty_location is true' do
        it 'returns false, does not unstick and calls use_primary!' do
          expect(load_balancer).not_to receive(:select_up_to_date_host)

          expect(redis).not_to receive(:del)
          expect(::Gitlab::Database::LoadBalancing::SessionMap.current(load_balancer)).to receive(:use_primary!)

          expect(sticking.find_caught_up_replica(:user, 42, use_primary_on_empty_location: true)).to eq(false)
        end
      end
    end

    context 'when all replicas have caught up' do
      it 'returns true and unsticks' do
        expect(load_balancer).to receive(:select_up_to_date_host).with(last_write_location)
          .and_return(::Gitlab::Database::LoadBalancing::LoadBalancer::ALL_CAUGHT_UP)

        expect(redis)
          .to receive(:del)
          .with("database-load-balancing/write-location/#{load_balancer.name}/user/42")

        expect(sticking.find_caught_up_replica(:user, 42)).to eq(true)
      end
    end

    context 'when only some of the replicas have caught up' do
      it 'returns true and does not unstick' do
        expect(load_balancer).to receive(:select_up_to_date_host).with(last_write_location)
          .and_return(::Gitlab::Database::LoadBalancing::LoadBalancer::ANY_CAUGHT_UP)

        expect(redis).not_to receive(:del)

        expect(sticking.find_caught_up_replica(:user, 42)).to eq(true)
      end
    end

    context 'when none of the replicas have caught up' do
      before do
        allow(load_balancer).to receive(:select_up_to_date_host).with(last_write_location)
          .and_return(::Gitlab::Database::LoadBalancing::LoadBalancer::NONE_CAUGHT_UP)
      end

      it 'returns false, does not unstick and calls use_primary!' do
        expect(redis).not_to receive(:del)
        expect(::Gitlab::Database::LoadBalancing::SessionMap.current(load_balancer)).to receive(:use_primary!)

        expect(sticking.find_caught_up_replica(:user, 42)).to eq(false)
      end

      context 'when use_primary_on_failure is false' do
        it 'does not call use_primary!' do
          expect(redis).not_to receive(:del)
          expect(::Gitlab::Database::LoadBalancing::SessionMap.current(load_balancer)).not_to receive(:use_primary!)

          expect(sticking.find_caught_up_replica(:user, 42, use_primary_on_failure: false)).to eq(false)
        end
      end
    end
  end

  shared_examples 'sticking' do
    it 'sticks an entity to the primary', :aggregate_failures do
      allow(ActiveRecord::Base.load_balancer)
        .to receive(:primary_only?)
        .and_return(false)

      ids.each do |id|
        expect(redis)
          .to receive(:set)
          .with("database-load-balancing/write-location/#{load_balancer.name}/user/#{id}", 'the-primary-lsn', ex: 30)
      end

      expect(Gitlab::Database::LoadBalancing::SessionMap.current(load_balancer)).to receive(:use_primary!)

      subject
    end

    it 'does not update the write location when no replicas are used' do
      expect(sticking).not_to receive(:set_write_location_for)

      subject
    end
  end

  describe '#stick' do
    it_behaves_like 'sticking' do
      let(:ids) { [42] }
      subject { sticking.stick(:user, ids.first) }
    end
  end

  describe '#bulk_stick' do
    it_behaves_like 'sticking' do
      let(:ids) { [42, 43] }
      subject { sticking.bulk_stick(:user, ids) }
    end
  end
end
