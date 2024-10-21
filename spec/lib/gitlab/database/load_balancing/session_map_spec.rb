# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LoadBalancing::SessionMap, feature_category: :database do
  let(:lb) { ::ApplicationRecord.load_balancer }

  describe '.current' do
    let(:session) { Gitlab::Database::LoadBalancing::Session.new }

    before do
      described_class.clear_session
    end

    context 'when feature flag is disabled' do
      before do
        described_class.current(lb) # initialise a SessionMap
        stub_feature_flags(use_load_balancing_session_map: false)
      end

      it 'returns sessions from Gitlab::Database::LoadBalancing::Session.current' do
        expect(described_class.current(lb)).to eq(Gitlab::Database::LoadBalancing::Session.current)
      end
    end

    context 'when feature flag lookup returns unexpected error' do
      before do
        allow(Feature).to receive(:enabled?).and_raise(StandardError)
      end

      it 'tracks exception and return false' do
        # behaves as if feature flag is disabled
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(StandardError)
        expect(described_class.current(lb)).to eq(Gitlab::Database::LoadBalancing::Session.current)
      end
    end

    context 'when already initialised' do
      before do
        described_class.current(lb)
      end

      it 're-use memoized SessionMap' do
        expect(described_class).not_to receive(:new)
        described_class.current(lb)
      end
    end

    context 'when using a non-rake runtime' do
      before do
        allow_next_instance_of(described_class) do |inst|
          allow(inst).to receive(:lookup).and_return(session)
        end
      end

      it 'returns desired Session instance' do
        expect(described_class.current(lb)).to eq(session)
      end
    end

    context 'when using a rake runtime' do
      let(:pri_session) { Gitlab::Database::LoadBalancing::Session.new }
      let(:pri_lb) { instance_double('Gitlab::Database::LoadBalancing::LoadBalancer', name: :primary) }

      before do
        allow(Gitlab::Runtime).to receive(:rake?).and_return(true)
        sm = described_class.new
        sm.session_map[:primary] = pri_session
        RequestStore[described_class::CACHE_KEY] = sm
      end

      after do
        RequestStore[described_class::CACHE_KEY] = nil
      end

      it 'returns desired Session instance' do
        expect(described_class.current(pri_lb)).to eq(pri_session)
      end
    end

    context 'when receiving invalid db type' do
      using RSpec::Parameterized::TableSyntax

      let(:pri_lb) { instance_double('Gitlab::Database::LoadBalancing::LoadBalancer', name: :primary) }
      let(:invalid_lb) { instance_double('Gitlab::Database::LoadBalancing::LoadBalancer', name: :invalid) }

      where(:runtime, :db, :error) do
        :rake?  | :primary | false
        :rake?  | :invalid | true

        :puma?  | :primary | true
        :puma?  | :invalid | true

        :sidekiq?  | :primary | true
        :sidekiq?  | :invalid | true

        :test_suite?  | :primary | true
        :test_suite?  | :invalid | true
      end

      with_them do
        let(:lb) { instance_double('Gitlab::Database::LoadBalancing::LoadBalancer', name: db) }

        before do
          allow(Gitlab::Runtime).to receive(runtime).and_return(true)
          allow(Gitlab::Runtime).to receive(:safe_identify).and_return(runtime)
        end

        subject(:current) { described_class.current(lb) }

        it 'handles invalid db' do
          if error
            expect do
              current
            end.to raise_error(instance_of(Gitlab::Database::LoadBalancing::SessionMap::InvalidLoadBalancerNameError))
          else
            expect(current).to be_instance_of(Gitlab::Database::LoadBalancing::Session)
          end
        end
      end

      it 'handles unknown runtimes' do
        allow(Gitlab::Runtime).to receive(:rake?).and_return(false)
        allow(Gitlab::Runtime).to receive(:safe_identify).and_return(nil)

        expect(described_class.current(pri_lb)).to be_instance_of(Gitlab::Database::LoadBalancing::Session)
        expect do
          described_class.current(invalid_lb)
        end.to raise_error(instance_of(Gitlab::Database::LoadBalancing::SessionMap::InvalidLoadBalancerNameError))
      end
    end
  end

  describe '.clear_session' do
    before do
      described_class.current(::ApplicationRecord.load_balancer)
    end

    it 'clears instance from RequestStore' do
      described_class.clear_session

      expect(RequestStore[described_class::CACHE_KEY]).to eq(nil)
    end

    context 'when feature flag is disabled' do
      before do
        described_class.current(lb) # initialise a SessionMap
        stub_feature_flags(use_load_balancing_session_map: false)
      end

      it 'clears session from Gitlab::Database::LoadBalancing::Session.current' do
        expect(Gitlab::Database::LoadBalancing::Session.current).not_to eq(nil)

        described_class.clear_session

        expect(RequestStore[Gitlab::Database::LoadBalancing::Session::CACHE_KEY]).to eq(nil)
      end
    end
  end

  describe '.without_sticky_writes' do
    let(:dbs) { [::ApplicationRecord, ::Ci::ApplicationRecord] }
    let(:names) { dbs.map { |m| m.load_balancer.name }.uniq }

    let(:scoped_session) { Gitlab::Database::LoadBalancing::ScopedSessions.new(dbs, {}) }

    before do
      described_class.clear_session
      # This makes the spec more robust in single-db scenarios
      allow(Gitlab::Database::LoadBalancing).to receive(:names).and_return([:main, :ci])
      described_class.current(::ApplicationRecord.load_balancer)
    end

    it 'initialises ScopedSessions with all valid lb names and calls ignore_writes' do
      expect(Gitlab::Database::LoadBalancing::ScopedSessions)
        .to receive(:new).with(names, RequestStore[described_class::CACHE_KEY].session_map).and_return(scoped_session)

      expect(scoped_session).to receive(:ignore_writes).and_yield

      described_class.without_sticky_writes do
        # exact logic for ignore_writes is tested in `.with_sessions` test suite
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(use_load_balancing_session_map: false)
      end

      it 'calls Gitlab::Database::LoadBalancing::Session instead' do
        expect(Gitlab::Database::LoadBalancing::Session).to receive(:without_sticky_writes).and_yield

        described_class.without_sticky_writes do
          # exact logic for ignore_writes is tested in `.with_sessions` test suite
        end
      end
    end
  end

  describe '.with_sessions' do
    let(:main_lb) { instance_double('Gitlab::Database::LoadBalancing::LoadBalancer', name: :main) }
    let(:ci_lb) { instance_double('Gitlab::Database::LoadBalancing::LoadBalancer', name: :ci) }
    let(:sec_lb) { instance_double('Gitlab::Database::LoadBalancing::LoadBalancer', name: :sec) }
    let(:invalid_lb) { instance_double('Gitlab::Database::LoadBalancing::LoadBalancer', name: :invalid) }

    let(:main) { instance_double('ActiveRecord::Base', load_balancer: main_lb) }
    let(:ci) { instance_double('ActiveRecord::Base', load_balancer: ci_lb) }
    let(:sec) { instance_double('ActiveRecord::Base', load_balancer: sec_lb) }
    let(:invalid) { instance_double('ActiveRecord::Base', load_balancer: invalid_lb) }

    let(:all_dbs) { [main, ci, sec] }
    let(:scoped_dbs) { [main, ci] }

    before do
      described_class.clear_session

      # This makes the spec more robust in single-db scenarios
      allow(Gitlab::Database::LoadBalancing).to receive(:names).and_return(all_dbs)
    end

    subject(:with_sessions) { described_class.with_sessions(scoped_dbs) }

    it 'returns a ScopedSession instance' do
      expect(with_sessions)
        .to be_an_instance_of(Gitlab::Database::LoadBalancing::ScopedSessions)
    end

    it 'validates invalid dbs' do
      expect do
        described_class.with_sessions(scoped_dbs + [invalid])
      end.to raise_error(instance_of(described_class::InvalidLoadBalancerNameError))
    end

    context 'when use_load_balancing_session_map is disabled' do
      before do
        stub_feature_flags(use_load_balancing_session_map: false)
      end

      it 'returns Session instead of ScopedSession' do
        expect(with_sessions)
          .to be_an_instance_of(Gitlab::Database::LoadBalancing::Session)
      end
    end

    context 'when calling use_primary!' do
      it 'applies use_primary! to all sessions' do
        with_sessions.use_primary!

        scoped_dbs.each do |db|
          expect(described_class.current(db.load_balancer).use_primary?).to eq(true)
        end

        (all_dbs - scoped_dbs).each do |db|
          expect(described_class.current(db.load_balancer).use_primary?).to eq(false)
        end
      end
    end

    context 'when calling use_primary' do
      it 'applies use_primary to all scoped sessions' do
        with_sessions.use_primary do
          scoped_dbs.each do |db|
            expect(described_class.current(db.load_balancer).use_primary?).to eq(true)
          end

          (all_dbs - scoped_dbs).each do |db|
            expect(described_class.current(db.load_balancer).use_primary?).to eq(false)
          end
        end

        all_dbs.each do |db|
          expect(described_class.current(db.load_balancer).use_primary?).to eq(false)
        end
      end
    end

    context 'when calling ignore_writes' do
      it 'applies ignore_writes to all scoped sessions' do
        with_sessions.ignore_writes do
          all_dbs.each do |db|
            described_class.current(db.load_balancer).write!
          end

          scoped_dbs.each do |db|
            expect(described_class.current(db.load_balancer).performed_write?).to eq(true)
            expect(described_class.current(db.load_balancer).use_primary?).to eq(false)
          end

          (all_dbs - scoped_dbs).each do |db|
            expect(described_class.current(db.load_balancer).performed_write?).to eq(true)
            expect(described_class.current(db.load_balancer).use_primary?).to eq(true)
          end
        end
      end
    end

    context 'when calling use_replicas_for_read_queries' do
      it 'applies use_replicas_for_read_queries to all scoped sessions' do
        with_sessions.use_replicas_for_read_queries do
          scoped_dbs.each do |db|
            expect(described_class.current(db.load_balancer).use_replicas_for_read_queries?).to eq(true)
          end

          (all_dbs - scoped_dbs).each do |db|
            expect(described_class.current(db.load_balancer).use_replicas_for_read_queries?).to eq(false)
          end
        end

        all_dbs.each do |db|
          expect(described_class.current(db.load_balancer).use_replicas_for_read_queries?).to eq(false)
        end
      end
    end

    context 'when calling fallback_to_replicas_for_ambiguous_queries' do
      it 'applies fallback_to_replicas_for_ambiguous_queries to all scoped sessions' do
        with_sessions.fallback_to_replicas_for_ambiguous_queries do
          scoped_dbs.each do |db|
            expect(described_class.current(db.load_balancer).fallback_to_replicas_for_ambiguous_queries?).to eq(true)
          end

          (all_dbs - scoped_dbs).each do |db|
            expect(described_class.current(db.load_balancer).fallback_to_replicas_for_ambiguous_queries?).to eq(false)
          end
        end

        all_dbs.each do |db|
          expect(described_class.current(db.load_balancer).fallback_to_replicas_for_ambiguous_queries?).to eq(false)
        end
      end
    end
  end
end
