# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::Sticking, :redis, feature_category: :database do
  let(:load_balancer) { ActiveRecord::Base.load_balancer }
  let(:primary_write_location) { 'the-primary-lsn' }
  let(:last_write_location) { 'the-last-write-lsn' }
  let(:namespace) { 'user' }
  let(:location) { '0/1234ABED' }

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

  describe '#log_database_sticking_operations_enabled?' do
    it 'returns true when the feature flag is enabled' do
      stub_feature_flags(log_database_sticking_operations: true)
      expect(sticking.send(:log_database_sticking_operations_enabled?)).to be true
    end

    it 'returns false when the feature flag is disabled' do
      stub_feature_flags(log_database_sticking_operations: false)
      expect(sticking.send(:log_database_sticking_operations_enabled?)).to be false
    end
  end

  describe '#capture_stick_logs' do
    let(:id) { 123 }
    let(:ids) { [124, 125, 16] }

    context 'when logging is enabled and namespace is user' do
      before do
        stub_feature_flags(log_database_sticking_operations: true)

        allow(sticking).to receive(:with_primary_write_location).and_yield(location)
        allow(sticking).to receive(:set_write_location_for)
        allow(sticking).to receive(:use_primary!)
      end

      it 'logs the sticking operation with correct parameters' do
        expect(::Gitlab::Database::LoadBalancing::Logger).to receive(:info).with(
          event: :load_balancer_stick_logging,
          client_id: "#{namespace}/#{id}",
          stick_id: id,
          stick_type: namespace,
          current_lsn: location
        )
        sticking.stick(namespace, id)
      end

      it 'logs only the first ID for bulk sticking operations with correct parameters' do
        expect(::Gitlab::Database::LoadBalancing::Logger).to receive(:info).with(
          event: :load_balancer_stick_logging,
          client_id: "#{namespace}/#{ids.first}",
          stick_id: ids.first,
          stick_type: namespace,
          current_lsn: location
        )

        sticking.bulk_stick(namespace, ids)
      end
    end

    context 'when logging is disabled' do
      before do
        stub_feature_flags(log_database_sticking_operations: false)

        allow(sticking).to receive(:with_primary_write_location).and_yield(location)
        allow(sticking).to receive(:set_write_location_for)
        allow(sticking).to receive(:use_primary!)
      end

      it 'does not log anything' do
        expect(::Gitlab::Database::LoadBalancing::Logger).not_to receive(:info)

        sticking.stick(namespace, id)
      end
    end

    context 'when logging is enabled and namespace is not user' do
      let(:namespace) { 'project' }

      before do
        stub_feature_flags(log_database_sticking_operations: true)

        allow(sticking).to receive(:with_primary_write_location).and_yield(location)
        allow(sticking).to receive(:set_write_location_for)
        allow(sticking).to receive(:use_primary!)
      end

      it 'does not log anything' do
        expect(::Gitlab::Database::LoadBalancing::Logger).not_to receive(:info)

        sticking.bulk_stick(namespace, ids)
      end
    end
  end
end
