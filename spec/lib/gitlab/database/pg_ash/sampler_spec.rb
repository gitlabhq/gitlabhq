# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PgAsh::Sampler, :clean_gitlab_redis_shared_state,
  feature_category: :database do
  let(:conn) { ActiveRecord::Base.connection }
  let(:take_sample_sql) { 'SELECT ash.take_sample()' }
  let(:statement_timeout_sql) { "SET LOCAL statement_timeout TO '500ms'" }

  subject(:sampler) { described_class.new(conn) }

  before do
    stub_application_setting(pg_ash_sampling_enabled: true, pg_ash_sample_interval_seconds: 1)

    allow(Gitlab::Database::PgAsh).to receive(:execute).and_return([])
    allow(Kernel).to receive(:sleep)
  end

  # The caller passes a predicate that goes false when its thread shuts down.
  def execute(ticks:)
    remaining = ticks

    sampler.execute { (remaining -= 1) >= 0 }
  end

  describe '#execute' do
    it 'samples once per tick until the caller stops it' do
      execute(ticks: 3)

      expect(Gitlab::Database::PgAsh).to have_received(:execute).with(conn, take_sample_sql).thrice
    end

    it 'limits each sample with a statement timeout' do
      execute(ticks: 1)

      expect(Gitlab::Database::PgAsh).to have_received(:execute).with(conn, statement_timeout_sql).once
    end

    it 'writes the configured interval back to ash.config once per lease' do
      execute(ticks: 2)

      expect(Gitlab::Database::PgAsh).to have_received(:execute)
        .with(conn, a_string_matching(/UPDATE ash.config SET sampling_enabled = true/)).once
    end

    context 'when the interval changes while the loop is running' do
      it 'writes the new interval back to ash.config' do
        interval = 1
        allow(Gitlab::CurrentSettings).to receive(:pg_ash_sample_interval_seconds) { interval }
        # The admin saves a new interval while the holder waits for its next tick.
        allow(Kernel).to receive(:sleep) { interval = 5 }

        execute(ticks: 3)

        expect(Gitlab::Database::PgAsh).to have_received(:execute)
          .with(conn, a_string_matching(/sample_interval = 1 \*/)).once
        expect(Gitlab::Database::PgAsh).to have_received(:execute)
          .with(conn, a_string_matching(/sample_interval = 5 \*/)).once
      end
    end

    it 'waits out the remainder of the interval between samples' do
      execute(ticks: 1)

      expect(Kernel).to have_received(:sleep).with(a_value_between(0, 1)).once
    end

    context 'when another process holds the lease' do
      before do
        Gitlab::ExclusiveLease.new(sampler.lease_key, timeout: described_class::LEASE_TIMEOUT).try_obtain
      end

      it 'does not sample' do
        execute(ticks: 1)

        expect(Gitlab::Database::PgAsh).not_to have_received(:execute)
      end
    end

    context 'when sampling is disabled while the loop is running' do
      before do
        # One read at lease acquisition, one per loop iteration.
        allow(Gitlab::CurrentSettings).to receive(:pg_ash_sampling_enabled).and_return(true, true, false)
      end

      it 'stops without waiting for the caller' do
        execute(ticks: 5)

        expect(Gitlab::Database::PgAsh).to have_received(:execute).with(conn, take_sample_sql).once
      end

      it 'writes the disabled state back to ash.config' do
        execute(ticks: 5)

        expect(Gitlab::Database::PgAsh).to have_received(:execute)
          .with(conn, a_string_matching(/sampling_enabled = false/)).once
      end
    end

    context 'when the interval is out of range' do
      before do
        stub_application_setting(pg_ash_sample_interval_seconds: 600)
      end

      it 'clamps it to the maximum' do
        execute(ticks: 1)

        expect(Kernel).to have_received(:sleep).with(a_value_between(59, 60))
      end
    end

    context 'when the interval is nil' do
      before do
        stub_application_setting(pg_ash_sample_interval_seconds: nil)
      end

      it 'falls back to the minimum instead of raising' do
        execute(ticks: 1)

        expect(Kernel).to have_received(:sleep).with(a_value_between(0, 1))
      end
    end

    it 'keeps the lease longer than the largest allowed interval' do
      # A shorter lease expires mid-sleep and evicts the holder every tick.
      expect(described_class::LEASE_TIMEOUT).to be > described_class::MAX_SAMPLE_INTERVAL
    end

    context 'when a sample fails' do
      before do
        allow(Gitlab::Database::PgAsh).to receive(:execute)
          .with(conn, take_sample_sql).and_raise(ActiveRecord::StatementInvalid, 'boom')
      end

      it 'gives up after consecutive failures instead of killing the caller' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).once

        expect { execute(ticks: 100) }.not_to raise_error

        expect(Gitlab::Database::PgAsh).to have_received(:execute)
          .with(conn, take_sample_sql).exactly(described_class::MAX_CONSECUTIVE_ERRORS).times
      end

      it 'counts the failure' do
        allow(Gitlab::ErrorTracking).to receive(:track_exception)

        counter = instance_double(Prometheus::Client::Counter, increment: nil)
        allow(Gitlab::Metrics).to receive(:counter)
          .with(:gitlab_pg_ash_sampler_errors_total, anything).and_return(counter)

        execute(ticks: 100)

        expect(counter).to have_received(:increment).exactly(described_class::MAX_CONSECUTIVE_ERRORS).times
      end
    end

    context 'when reconciling ash.config fails' do
      before do
        allow(Gitlab::Database::PgAsh).to receive(:execute)
          .with(conn, a_string_matching(/UPDATE ash.config/)).and_raise(ActiveRecord::StatementInvalid, 'boom')
      end

      it 'reports the error instead of letting it kill the calling thread' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).once

        expect { execute(ticks: 1) }.not_to raise_error
      end
    end

    context 'when renewing the lease fails' do
      before do
        allow(sampler).to receive(:renew_lease!).and_raise(Redis::CannotConnectError, 'boom')
      end

      it 'reports the error instead of letting it kill the calling thread' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).once

        expect { execute(ticks: 1) }.not_to raise_error
      end
    end

    context 'when ash.config reports its own counters' do
      let(:counters) { { 'skipped_samples' => '2', 'missed_samples' => '3', 'insert_errors' => '4' } }

      before do
        allow(Gitlab::Database::PgAsh).to receive(:execute)
          .with(conn, a_string_matching(/SELECT skipped_samples/)).and_return([counters])
      end

      it 'exports each counter through its own gauge' do
        gauges = described_class::CONFIG_COUNTERS.each_key.to_h do |counter|
          [:"gitlab_pg_ash_#{counter}", instance_double(Prometheus::Client::Gauge, set: nil)]
        end
        allow(Gitlab::Metrics).to receive(:gauge) { |name, *| gauges.fetch(name) }

        execute(ticks: 1)

        expect(gauges[:gitlab_pg_ash_skipped_samples]).to have_received(:set).with({}, 2)
        expect(gauges[:gitlab_pg_ash_missed_samples]).to have_received(:set).with({}, 3)
        expect(gauges[:gitlab_pg_ash_insert_errors]).to have_received(:set).with({}, 4)
      end
    end
  end
end
