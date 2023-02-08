# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::Sticking, :redis do
  let(:sticking) do
    described_class.new(ActiveRecord::Base.load_balancer)
  end

  after do
    Gitlab::Database::LoadBalancing::Session.clear_session
  end

  shared_examples 'sticking' do
    before do
      allow(ActiveRecord::Base.load_balancer)
        .to receive(:primary_write_location)
        .and_return('foo')
    end

    it 'sticks an entity to the primary', :aggregate_failures do
      allow(ActiveRecord::Base.load_balancer)
        .to receive(:primary_only?)
        .and_return(false)

      ids.each do |id|
        expect(sticking)
          .to receive(:set_write_location_for)
          .with(:user, id, 'foo')
      end

      expect(Gitlab::Database::LoadBalancing::Session.current)
        .to receive(:use_primary!)

      subject
    end

    it 'does not update the write location when no replicas are used' do
      expect(sticking).not_to receive(:set_write_location_for)

      subject
    end
  end

  shared_examples 'tracking status in redis' do
    describe '#stick_or_unstick_request' do
      it 'sticks or unsticks a single object and updates the Rack environment' do
        expect(sticking)
          .to receive(:unstick_or_continue_sticking)
          .with(:user, 42)

        env = {}

        sticking.stick_or_unstick_request(env, :user, 42)

        expect(env[Gitlab::Database::LoadBalancing::RackMiddleware::STICK_OBJECT].to_a)
          .to eq([[sticking, :user, 42]])
      end

      it 'sticks or unsticks multiple objects and updates the Rack environment' do
        expect(sticking)
          .to receive(:unstick_or_continue_sticking)
          .with(:user, 42)
          .ordered

        expect(sticking)
          .to receive(:unstick_or_continue_sticking)
          .with(:runner, '123456789')
          .ordered

        env = {}

        sticking.stick_or_unstick_request(env, :user, 42)
        sticking.stick_or_unstick_request(env, :runner, '123456789')

        expect(env[Gitlab::Database::LoadBalancing::RackMiddleware::STICK_OBJECT].to_a).to eq(
          [
            [sticking, :user, 42],
            [sticking, :runner,
            '123456789']
          ])
      end
    end

    describe '#stick_if_necessary' do
      it 'does not stick if no write was performed' do
        allow(Gitlab::Database::LoadBalancing::Session.current)
          .to receive(:performed_write?)
          .and_return(false)

        expect(sticking).not_to receive(:stick)

        sticking.stick_if_necessary(:user, 42)
      end

      it 'sticks to the primary if a write was performed' do
        allow(Gitlab::Database::LoadBalancing::Session.current)
          .to receive(:performed_write?)
          .and_return(true)

        expect(sticking)
          .to receive(:stick)
          .with(:user, 42)

        sticking.stick_if_necessary(:user, 42)
      end
    end

    describe '#all_caught_up?' do
      let(:lb) { ActiveRecord::Base.load_balancer }
      let(:last_write_location) { 'foo' }

      before do
        allow(ActiveSupport::Notifications).to receive(:instrument).and_call_original

        allow(sticking)
          .to receive(:last_write_location_for)
          .with(:user, 42)
          .and_return(last_write_location)
      end

      context 'when no write location could be found' do
        let(:last_write_location) { nil }

        it 'returns true' do
          expect(lb).not_to receive(:select_up_to_date_host)

          expect(sticking.all_caught_up?(:user, 42)).to eq(true)
        end
      end

      context 'when all secondaries have caught up' do
        before do
          allow(lb).to receive(:select_up_to_date_host).with('foo').and_return(true)
        end

        it 'returns true, and unsticks' do
          expect(sticking)
            .to receive(:unstick)
            .with(:user, 42)

          expect(sticking.all_caught_up?(:user, 42)).to eq(true)
        end

        it 'notifies with the proper event payload' do
          expect(ActiveSupport::Notifications)
            .to receive(:instrument)
            .with('caught_up_replica_pick.load_balancing', { result: true })
            .and_call_original

          sticking.all_caught_up?(:user, 42)
        end
      end

      context 'when the secondaries have not yet caught up' do
        before do
          allow(lb).to receive(:select_up_to_date_host).with('foo').and_return(false)
        end

        it 'returns false' do
          expect(sticking.all_caught_up?(:user, 42)).to eq(false)
        end

        it 'notifies with the proper event payload' do
          expect(ActiveSupport::Notifications)
            .to receive(:instrument)
            .with('caught_up_replica_pick.load_balancing', { result: false })
            .and_call_original

          sticking.all_caught_up?(:user, 42)
        end
      end
    end

    describe '#unstick_or_continue_sticking' do
      let(:lb) { ActiveRecord::Base.load_balancer }

      it 'simply returns if no write location could be found' do
        allow(sticking)
          .to receive(:last_write_location_for)
          .with(:user, 42)
          .and_return(nil)

        expect(lb).not_to receive(:select_up_to_date_host)

        sticking.unstick_or_continue_sticking(:user, 42)
      end

      it 'unsticks if all secondaries have caught up' do
        allow(sticking)
          .to receive(:last_write_location_for)
          .with(:user, 42)
          .and_return('foo')

        allow(lb).to receive(:select_up_to_date_host).with('foo').and_return(true)

        expect(sticking)
          .to receive(:unstick)
          .with(:user, 42)

        sticking.unstick_or_continue_sticking(:user, 42)
      end

      it 'continues using the primary if the secondaries have not yet caught up' do
        allow(sticking)
          .to receive(:last_write_location_for)
          .with(:user, 42)
          .and_return('foo')

        allow(lb).to receive(:select_up_to_date_host).with('foo').and_return(false)

        expect(Gitlab::Database::LoadBalancing::Session.current)
          .to receive(:use_primary!)

        sticking.unstick_or_continue_sticking(:user, 42)
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

    describe '#mark_primary_write_location' do
      it 'updates the write location with the load balancer' do
        allow(ActiveRecord::Base.load_balancer)
          .to receive(:primary_write_location)
          .and_return('foo')

        allow(ActiveRecord::Base.load_balancer)
          .to receive(:primary_only?)
          .and_return(false)

        expect(sticking)
          .to receive(:set_write_location_for)
          .with(:user, 42, 'foo')

        sticking.mark_primary_write_location(:user, 42)
      end

      it 'does nothing when no replicas are used' do
        expect(sticking).not_to receive(:set_write_location_for)

        sticking.mark_primary_write_location(:user, 42)
      end
    end

    describe '#unstick' do
      it 'removes the sticking data from Redis' do
        sticking.set_write_location_for(:user, 4, 'foo')
        sticking.unstick(:user, 4)

        expect(sticking.last_write_location_for(:user, 4)).to be_nil
      end
    end

    describe '#last_write_location_for' do
      it 'returns the last WAL write location for a user' do
        sticking.set_write_location_for(:user, 4, 'foo')

        expect(sticking.last_write_location_for(:user, 4)).to eq('foo')
      end
    end

    describe '#select_caught_up_replicas' do
      let(:lb) { ActiveRecord::Base.load_balancer }

      context 'with no write location' do
        before do
          allow(sticking)
            .to receive(:last_write_location_for)
            .with(:project, 42)
            .and_return(nil)
        end

        it 'returns false and does not try to find caught up hosts' do
          expect(lb).not_to receive(:select_up_to_date_host)
          expect(sticking.select_caught_up_replicas(:project, 42)).to be false
        end
      end

      context 'with write location' do
        before do
          allow(sticking)
            .to receive(:last_write_location_for)
            .with(:project, 42)
            .and_return('foo')
        end

        it 'returns true, selects hosts, and unsticks if any secondary has caught up' do
          expect(lb).to receive(:select_up_to_date_host).and_return(true)
          expect(sticking)
            .to receive(:unstick)
            .with(:project, 42)
          expect(sticking.select_caught_up_replicas(:project, 42)).to be true
        end
      end
    end
  end

  context 'with multi-store feature flags turned on' do
    it_behaves_like 'tracking status in redis'
  end

  context 'when both multi-store feature flags are off' do
    before do
      stub_feature_flags(use_primary_and_secondary_stores_for_db_load_balancing: false)
      stub_feature_flags(use_primary_store_as_default_for_db_load_balancing: false)
    end

    it_behaves_like 'tracking status in redis'
  end

  describe '#redis_key_for' do
    it 'returns a String' do
      expect(sticking.redis_key_for(:user, 42))
        .to eq('database-load-balancing/write-location/main/user/42')
    end
  end
end
