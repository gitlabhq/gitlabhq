# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::Sticking, :redis do
  after do
    Gitlab::Database::LoadBalancing::Session.clear_session
  end

  describe '.stick_if_necessary' do
    context 'when sticking is disabled' do
      it 'does not perform any sticking' do
        expect(described_class).not_to receive(:stick)

        described_class.stick_if_necessary(:user, 42)
      end
    end

    context 'when sticking is enabled' do
      before do
        allow(Gitlab::Database::LoadBalancing).to receive(:enable?)
          .and_return(true)
      end

      it 'does not stick if no write was performed' do
        allow(Gitlab::Database::LoadBalancing::Session.current)
          .to receive(:performed_write?)
          .and_return(false)

        expect(described_class).not_to receive(:stick)

        described_class.stick_if_necessary(:user, 42)
      end

      it 'sticks to the primary if a write was performed' do
        allow(Gitlab::Database::LoadBalancing::Session.current)
          .to receive(:performed_write?)
          .and_return(true)

        expect(described_class).to receive(:stick).with(:user, 42)

        described_class.stick_if_necessary(:user, 42)
      end
    end
  end

  describe '.all_caught_up?' do
    let(:lb) { double(:lb) }
    let(:last_write_location) { 'foo' }

    before do
      allow(described_class).to receive(:load_balancer).and_return(lb)

      allow(described_class).to receive(:last_write_location_for)
        .with(:user, 42)
        .and_return(last_write_location)
    end

    context 'when no write location could be found' do
      let(:last_write_location) { nil }

      it 'returns true' do
        allow(described_class).to receive(:last_write_location_for)
          .with(:user, 42)
          .and_return(nil)

        expect(lb).not_to receive(:all_caught_up?)

        expect(described_class.all_caught_up?(:user, 42)).to eq(true)
      end
    end

    context 'when all secondaries have caught up' do
      before do
        allow(lb).to receive(:all_caught_up?).with('foo').and_return(true)
      end

      it 'returns true, and unsticks' do
        expect(described_class).to receive(:unstick).with(:user, 42)

        expect(described_class.all_caught_up?(:user, 42)).to eq(true)
      end

      it 'notifies with the proper event payload' do
        expect(ActiveSupport::Notifications)
          .to receive(:instrument)
          .with('caught_up_replica_pick.load_balancing', { result: true })
          .and_call_original

        described_class.all_caught_up?(:user, 42)
      end
    end

    context 'when the secondaries have not yet caught up' do
      before do
        allow(lb).to receive(:all_caught_up?).with('foo').and_return(false)
      end

      it 'returns false' do
        expect(described_class.all_caught_up?(:user, 42)).to eq(false)
      end

      it 'notifies with the proper event payload' do
        expect(ActiveSupport::Notifications)
          .to receive(:instrument)
          .with('caught_up_replica_pick.load_balancing', { result: false })
          .and_call_original

        described_class.all_caught_up?(:user, 42)
      end
    end
  end

  describe '.unstick_or_continue_sticking' do
    let(:lb) { double(:lb) }

    before do
      allow(described_class).to receive(:load_balancer).and_return(lb)
    end

    it 'simply returns if no write location could be found' do
      allow(described_class).to receive(:last_write_location_for)
        .with(:user, 42)
        .and_return(nil)

      expect(lb).not_to receive(:all_caught_up?)

      described_class.unstick_or_continue_sticking(:user, 42)
    end

    it 'unsticks if all secondaries have caught up' do
      allow(described_class).to receive(:last_write_location_for)
        .with(:user, 42)
        .and_return('foo')

      allow(lb).to receive(:all_caught_up?).with('foo').and_return(true)

      expect(described_class).to receive(:unstick).with(:user, 42)

      described_class.unstick_or_continue_sticking(:user, 42)
    end

    it 'continues using the primary if the secondaries have not yet caught up' do
      allow(described_class).to receive(:last_write_location_for)
        .with(:user, 42)
        .and_return('foo')

      allow(lb).to receive(:all_caught_up?).with('foo').and_return(false)

      expect(Gitlab::Database::LoadBalancing::Session.current)
        .to receive(:use_primary!)

      described_class.unstick_or_continue_sticking(:user, 42)
    end
  end

  RSpec.shared_examples 'sticking' do
    context 'when sticking is disabled' do
      it 'does not perform any sticking', :aggregate_failures do
        expect(described_class).not_to receive(:set_write_location_for)
        expect(Gitlab::Database::LoadBalancing::Session.current).not_to receive(:use_primary!)

        described_class.bulk_stick(:user, ids)
      end
    end

    context 'when sticking is enabled' do
      before do
        allow(Gitlab::Database::LoadBalancing).to receive(:configured?).and_return(true)

        lb = double(:lb, primary_write_location: 'foo')

        allow(described_class).to receive(:load_balancer).and_return(lb)
      end

      it 'sticks an entity to the primary', :aggregate_failures do
        ids.each do |id|
          expect(described_class).to receive(:set_write_location_for)
                                       .with(:user, id, 'foo')
        end

        expect(Gitlab::Database::LoadBalancing::Session.current)
          .to receive(:use_primary!)

        subject
      end
    end
  end

  describe '.stick' do
    it_behaves_like 'sticking' do
      let(:ids) { [42] }
      subject { described_class.stick(:user, ids.first) }
    end
  end

  describe '.bulk_stick' do
    it_behaves_like 'sticking' do
      let(:ids) { [42, 43] }
      subject { described_class.bulk_stick(:user, ids) }
    end
  end

  describe '.mark_primary_write_location' do
    context 'when enabled' do
      before do
        allow(Gitlab::Database::LoadBalancing).to receive(:enable?).and_return(true)
        allow(Gitlab::Database::LoadBalancing).to receive(:configured?).and_return(true)
      end

      it 'updates the write location with the load balancer' do
        lb = double(:lb, primary_write_location: 'foo')

        allow(described_class).to receive(:load_balancer).and_return(lb)

        expect(described_class).to receive(:set_write_location_for)
          .with(:user, 42, 'foo')

        described_class.mark_primary_write_location(:user, 42)
      end
    end

    context 'when load balancing is configured but not enabled' do
      before do
        allow(Gitlab::Database::LoadBalancing).to receive(:enable?).and_return(false)
        allow(Gitlab::Database::LoadBalancing).to receive(:configured?).and_return(true)
      end

      it 'updates the write location with the main ActiveRecord connection' do
        allow(described_class).to receive(:load_balancer).and_return(nil)
        expect(ActiveRecord::Base).to receive(:connection).and_call_original
        expect(described_class).to receive(:set_write_location_for)
          .with(:user, 42, anything)

        described_class.mark_primary_write_location(:user, 42)
      end

      context 'when write location is nil' do
        before do
          allow(Gitlab::Database).to receive(:get_write_location).and_return(nil)
        end

        it 'does not update the write location' do
          expect(described_class).not_to receive(:set_write_location_for)

          described_class.mark_primary_write_location(:user, 42)
        end
      end
    end

    context 'when load balancing is disabled' do
      before do
        allow(Gitlab::Database::LoadBalancing).to receive(:enable?).and_return(false)
        allow(Gitlab::Database::LoadBalancing).to receive(:configured?).and_return(false)
      end

      it 'updates the write location with the main ActiveRecord connection' do
        expect(described_class).not_to receive(:set_write_location_for)

        described_class.mark_primary_write_location(:user, 42)
      end
    end
  end

  describe '.unstick' do
    it 'removes the sticking data from Redis' do
      described_class.set_write_location_for(:user, 4, 'foo')
      described_class.unstick(:user, 4)

      expect(described_class.last_write_location_for(:user, 4)).to be_nil
    end
  end

  describe '.last_write_location_for' do
    it 'returns the last WAL write location for a user' do
      described_class.set_write_location_for(:user, 4, 'foo')

      expect(described_class.last_write_location_for(:user, 4)).to eq('foo')
    end
  end

  describe '.redis_key_for' do
    it 'returns a String' do
      expect(described_class.redis_key_for(:user, 42))
        .to eq('database-load-balancing/write-location/user/42')
    end
  end

  describe '.load_balancer' do
    it 'returns a the load balancer' do
      proxy = double(:proxy)

      expect(Gitlab::Database::LoadBalancing).to receive(:proxy)
        .and_return(proxy)

      expect(proxy).to receive(:load_balancer)

      described_class.load_balancer
    end
  end

  describe '.select_caught_up_replicas' do
    let(:lb) { double(:lb) }

    before do
      allow(described_class).to receive(:load_balancer).and_return(lb)
    end

    context 'with no write location' do
      before do
        allow(described_class).to receive(:last_write_location_for)
          .with(:project, 42).and_return(nil)
      end

      it 'returns false and does not try to find caught up hosts' do
        expect(described_class).not_to receive(:select_caught_up_hosts)
        expect(described_class.select_caught_up_replicas(:project, 42)).to be false
      end
    end

    context 'with write location' do
      before do
        allow(described_class).to receive(:last_write_location_for)
          .with(:project, 42).and_return('foo')
      end

      it 'returns true, selects hosts, and unsticks if any secondary has caught up' do
        expect(lb).to receive(:select_caught_up_hosts).and_return(true)
        expect(described_class).to receive(:unstick).with(:project, 42)
        expect(described_class.select_caught_up_replicas(:project, 42)).to be true
      end
    end
  end
end
