# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::LockAcquisition::Watcher, feature_category: :database do
  let(:logger) { instance_spy(Gitlab::JsonLogger) }
  let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }
  let(:pool) do
    instance_double(ActiveRecord::ConnectionAdapters::ConnectionPool, checkout_timeout: 5.0)
  end

  subject(:watcher) do
    described_class.new(
      pool: pool,
      ddl_session: { pid: 12345, backend_start: '2026-08-21 10:00:00+00' },
      tables: %w[projects],
      pool_capacity: 50,
      logger: logger
    )
  end

  before do
    allow(connection).to receive(:execute)
    allow(connection).to receive(:quote) { |value| "'#{value}'" }
    allow(connection).to receive(:select_value).with('SHOW statement_timeout').and_return('2min')
    allow(connection).to receive(:select_value).with(/pg_database/).and_return(16406)
    allow(connection).to receive(:select_value).with(/pg_partition_tree/).and_return(1)
    allow(connection).to receive(:table_exists?).and_return(true)

    watcher.send(:prepare, connection)
  end

  def observation(blocking_pids: '', queued_waiters: 0, unfiltered_waiters: nil, wait_event_type: 'Lock')
    {
      'blocking_pids' => blocking_pids,
      'queued_waiters' => queued_waiters,
      'unfiltered_waiters' => unfiltered_waiters || queued_waiters,
      'ddl_wait_event_type' => wait_event_type
    }
  end

  def verdict
    watcher.send(:verdict)
  end

  # The bill charges depth x elapsed; specs simulate elapsed time by
  # backdating the accrual clock instead of sleeping.
  def backdate_last_accrual(seconds)
    watcher.send(:bill).instance_variable_set(
      :@last_accrual_at, Process.clock_gettime(Process::CLOCK_MONOTONIC) - seconds
    )
  end

  describe 'observing' do
    it 'logs when the blocker set changes and tracks the summary', :aggregate_failures do
      allow(connection).to receive(:select_one).and_return(observation(blocking_pids: '111,222', queued_waiters: 1))

      watcher.send(:poll, connection)

      expect(logger).to have_received(:info).with(
        hash_including(message: 'Lock acquisition watch', blocking_pids: [111, 222], queued_waiters: 1)
      )

      watcher.stop

      expect(logger).to have_received(:info).with(
        hash_including(message: 'Lock acquisition watch finished', distinct_blocker_pids: 2, peak_queued_waiters: 1)
      )
    end

    it 'does not log unchanged blocker sets between sampling polls' do
      allow(connection).to receive(:select_one).and_return(observation(blocking_pids: '111'))

      2.times { watcher.send(:poll, connection) }

      expect(logger).to have_received(:info)
        .with(hash_including(message: 'Lock acquisition watch')).once
    end

    it 'excludes prepared transaction blockers (pid 0) from the distinct pid count' do
      allow(connection).to receive(:select_one).and_return(observation(blocking_pids: '0,111'))

      watcher.send(:poll, connection)
      watcher.stop

      expect(logger).to have_received(:info).with(
        hash_including(message: 'Lock acquisition watch finished', distinct_blocker_pids: 1)
      )
    end
  end

  describe 'damage bill trips' do
    before do
      allow(connection).to receive(:select_value).with(/pg_cancel_backend/).and_return(true)
    end

    it 'accrues depth x elapsed and cancels once the window budget is spent', :aggregate_failures do
      allow(connection).to receive(:select_one).and_return(observation(queued_waiters: 4))

      watcher.send(:poll, connection) # first rectangle has ~zero width
      3.times do
        backdate_last_accrual(1.0)
        watcher.send(:poll, connection) # 4 + 4 + 4 = 12 >= 10
      end

      expect(verdict.canceled).to be(true)
      expect(verdict.trip_reason).to eq(:accumulated_wait)
      expect(connection).to have_received(:select_value)
        .with(/pg_cancel_backend.*state = 'active'.*wait_event_type = 'Lock'/m).once
    end

    it 'does not cancel while the bill is under budget' do
      allow(connection).to receive(:select_one).and_return(observation(queued_waiters: 2))

      watcher.send(:poll, connection)
      3.times do
        backdate_last_accrual(1.0)
        watcher.send(:poll, connection) # 2 + 2 + 2 = 6 < 10
      end

      expect(verdict.canceled).to be(false)
    end

    it 'labels a bill that fills on the first informative window poll as table_too_hot', :aggregate_failures do
      # Model real arming: the arming poll observes the DDL before it waits.
      allow(connection).to receive(:select_one)
        .and_return(observation(queued_waiters: 0, wait_event_type: 'Client'))
      watcher.send(:poll, connection)

      allow(connection).to receive(:select_one).and_return(observation(queued_waiters: 12))
      backdate_last_accrual(1.0)
      watcher.send(:poll, connection) # 12 x 1s on the window's first poll

      expect(verdict.canceled).to be(true)
      expect(verdict.trip_reason).to eq(:table_too_hot)
    end

    it 'resets the window bill when the watched session is not waiting', :aggregate_failures do
      allow(connection).to receive(:select_one).and_return(observation(queued_waiters: 4))

      watcher.send(:poll, connection)
      2.times do
        backdate_last_accrual(1.0)
        watcher.send(:poll, connection) # window bill 8
      end

      allow(connection).to receive(:select_one)
        .and_return(observation(queued_waiters: 0, wait_event_type: 'Client'))
      watcher.send(:poll, connection) # between attempts: reset

      allow(connection).to receive(:select_one).and_return(observation(queued_waiters: 4))
      backdate_last_accrual(1.0)
      watcher.send(:poll, connection) # fresh window: bill 4 < 10

      expect(verdict.canceled).to be(false)
    end

    it 'cancels on the run cap even when each window stays under budget', :aggregate_failures do
      between = observation(queued_waiters: 0, wait_event_type: 'Client')
      waiting = observation(queued_waiters: 4)

      3.times do
        allow(connection).to receive(:select_one).and_return(waiting)
        watcher.send(:poll, connection)
        2.times do
          backdate_last_accrual(1.0)
          watcher.send(:poll, connection) # +8 per window; run total 8, 16, 24
        end

        allow(connection).to receive(:select_one).and_return(between)
        watcher.send(:poll, connection)
      end

      expect(verdict.canceled).to be(true)
      expect(verdict.trip_reason).to eq(:accumulated_wait)
    end

    it 'does not bill or cancel when the watched session is not in a lock wait' do
      allow(connection).to receive(:select_one)
        .and_return(observation(queued_waiters: 12, wait_event_type: 'Client'))

      watcher.send(:poll, connection)
      backdate_last_accrual(1.0)
      watcher.send(:poll, connection)

      expect(verdict.canceled).to be(false)
    end

    it 'cancels immediately at the pool ceiling regardless of the bill', :aggregate_failures do
      small = described_class.new(
        pool: pool, ddl_session: { pid: 12345, backend_start: '2026-08-21 10:00:00+00' },
        tables: %w[projects], pool_capacity: 5, logger: logger
      )
      small.send(:prepare, connection) # ceiling = clamp(floor(0.4 x 5), 2, 20) = 2
      allow(connection).to receive(:select_one).and_return(observation(queued_waiters: 2))

      small.send(:poll, connection)

      expect(small.send(:verdict).canceled).to be(true)
      expect(small.send(:verdict).trip_reason).to eq(:pool_exhaustion)
    end

    it 'routes any blind interval during a wait to watch loss, regardless of spend', :aggregate_failures do
      watcher.instance_variable_set(:@armed, true)
      allow(connection).to receive(:select_one).and_return(observation(queued_waiters: 1))

      watcher.send(:poll, connection)
      backdate_last_accrual(3.0) # blindness; billable spend only 1 x 1.5s
      watcher.send(:poll, connection)

      expect(verdict.canceled).to be(false)
      expect(verdict.watch_lost).to be(true)
    end

    it 'never fires a congestion cancel on the same poll as a blindness watch loss', :aggregate_failures do
      watcher.instance_variable_set(:@armed, true)
      allow(connection).to receive(:select_one).and_return(observation(queued_waiters: 8))

      watcher.send(:poll, connection)
      backdate_last_accrual(2.5) # capped cost 8 x 1.5 = 12: crosses the budget too
      watcher.send(:poll, connection)

      expect(verdict.watch_lost).to be(true)
      expect(verdict.canceled).to be(false)
      expect(connection).to have_received(:select_value).with(/pg_cancel_backend/).once
    end

    it 'treats a blind failed poll during a wait as watch loss' do
      watcher.instance_variable_set(:@armed, true)
      allow(connection).to receive(:select_one).and_return(observation(queued_waiters: 2))
      watcher.send(:poll, connection) # establishes last depth and wait state

      backdate_last_accrual(3.0)
      allow(connection).to receive(:select_one).and_raise(PG::UnableToSend, 'gone')
      watcher.send(:resilient_poll, connection)

      expect(verdict.watch_lost).to be(true)
    end

    it 'bills a new attempt from its own start, not from the previous poll', :aggregate_failures do
      allow(connection).to receive(:select_one).and_return(observation(queued_waiters: 9))

      watcher.send(:start_attempt)
      backdate_last_accrual(5.0) # includes retry sleep; must not be billed
      watcher.send(:bill).instance_variable_set(
        :@attempt_started_at, Process.clock_gettime(Process::CLOCK_MONOTONIC) - 0.4
      )
      watcher.send(:poll, connection) # 9 x 0.4 = 3.6 < 10, and no blindness

      expect(verdict.canceled).to be(false)
      expect(verdict.watch_lost).to be(false)

      backdate_last_accrual(1.0)
      watcher.send(:poll, connection) # + 9 = 12.6 >= 10: real damage still bills

      expect(verdict.canceled).to be(true)
      expect(verdict.trip_reason).to eq(:accumulated_wait)
    end

    it 'does not bill or blame a blind interval that spans an attempt change' do
      allow(connection).to receive(:select_one).and_return(observation(queued_waiters: 2))
      watcher.send(:poll, connection) # last state: waiting at depth 2

      watcher.send(:start_attempt)
      backdate_last_accrual(3.0)
      watcher.instance_variable_set(:@armed, true)
      allow(connection).to receive(:select_one).and_raise(PG::UnableToSend, 'gone')
      watcher.send(:resilient_poll, connection)

      expect(verdict.watch_lost).to be(false)
    end

    it 'delivers a trip via a fresh connection when the poll connection dies at signal time', :aggregate_failures do
      fresh = instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
      allow(connection).to receive(:select_value).with(/pg_cancel_backend/).and_raise(PG::UnableToSend, 'gone')
      allow(pool).to receive(:checkout).and_return(fresh)
      allow(pool).to receive(:checkin)
      allow(fresh).to receive(:transaction).and_yield
      allow(fresh).to receive(:execute)
      allow(fresh).to receive(:select_value).with(/pg_cancel_backend/).and_return(true)
      allow(connection).to receive(:select_one).and_return(observation(queued_waiters: 12))

      watcher.send(:poll, connection)
      backdate_last_accrual(1.0)
      watcher.send(:poll, connection)

      expect(verdict.canceled).to be(true)
      expect(pool).to have_received(:checkin).with(fresh)
    end

    it 'keeps an undelivered decision and retries its delivery on the next poll', :aggregate_failures do
      allow(connection).to receive(:select_value).with(/pg_cancel_backend/).and_return(nil)
      allow(connection).to receive(:select_one).and_return(observation(queued_waiters: 12))

      watcher.send(:poll, connection)
      2.times do
        backdate_last_accrual(1.0)
        watcher.send(:poll, connection)
      end

      expect(verdict).to have_attributes(trip_reason: :accumulated_wait, canceled: false)
      expect(connection).to have_received(:select_value).with(/pg_cancel_backend/).twice
    end
  end

  it 'derives the handoff deadline from the pool checkout timeout' do
    expect(watcher.instance_variable_get(:@handoff_deadline_s)).to eq(5.0 + 2.5 + 1 + 1)
  end

  describe 'coordination with the retry loop' do
    let(:release) { Queue.new }

    before do
      stub_const("#{described_class}::POLL_INTERVAL_S", 0.05)
      allow(pool).to receive(:checkout).and_return(connection)
      allow(pool).to receive(:checkin)
      allow(connection).to receive(:select_value).with(/pg_cancel_backend/).and_return(nil)
    end

    after do
      release.push(true)
      watcher.stop
    end

    # Arms normally, then holds the next poll inside its query until released.
    def start_with_poll_in_flight
      polls = 0
      allow(connection).to receive(:select_one) do
        polls += 1
        release.pop if polls == 2
        observation
      end
      watcher.start
      250.times { polls >= 2 ? break : sleep(0.02) }
    end

    it 'answers begin_attempt only once the poll in flight has finished', :aggregate_failures do
      start_with_poll_in_flight
      requester = Thread.new { watcher.begin_attempt }

      expect(requester.join(0.2)).to be_nil
      release.push(true)

      expect(requester.join(2)).to eq(requester)
    end

    it 'refuses to start an attempt while the loop is stuck in a poll' do
      start_with_poll_in_flight
      watcher.instance_variable_set(:@handoff_deadline_s, 0.2)

      expect { watcher.begin_attempt }.to raise_error(described_class::SupervisionStalledError, /did not answer/)
    end

    it 'refuses to settle while the loop is stuck in a poll' do
      start_with_poll_in_flight
      watcher.instance_variable_set(:@handoff_deadline_s, 0.2)

      expect { watcher.settle }.to raise_error(described_class::SupervisionStalledError, /did not answer/)
    end

    it 'refuses to start an attempt once the loop has exited' do
      allow(connection).to receive(:select_one).and_return(observation)
      watcher.start
      allow(connection).to receive(:select_one).and_raise(PG::UnableToSend, 'gone')
      250.times { watcher.healthy? ? sleep(0.02) : break }

      expect { watcher.begin_attempt }.to raise_error(described_class::SupervisionStalledError, /has stopped/)
    end

    it 'answers a request still queued when the loop exits instead of letting it wait out the deadline',
      :aggregate_failures do
      in_flight = Queue.new
      polls = 0
      allow(connection).to receive(:select_one) do
        polls += 1
        next observation if polls == 1

        in_flight.push(true) && release.pop if polls == 3
        raise PG::UnableToSend, 'gone'
      end
      watcher.start
      watcher.instance_variable_set(:@handoff_deadline_s, 2)
      in_flight.pop
      requester = Thread.new do
        watcher.begin_attempt
      rescue described_class::SupervisionStalledError => e
        e
      end

      expect(requester.join(0.2)).to be_nil
      release.push(true)

      expect(requester.value).to have_attributes(message: 'watcher has stopped')
    end

    it 'ignores an unknown request and keeps serving', :aggregate_failures do
      allow(connection).to receive(:select_one).and_return(observation)
      watcher.start
      watcher.instance_variable_set(:@handoff_deadline_s, 0.2)

      expect(watcher.send(:request, :unknown)).to be_nil
      expect(watcher.healthy?).to be(true)
    end

    it 'settles only after a cancel in flight resolved, with one consistent verdict', :aggregate_failures do
      in_flight = Queue.new
      cancels = 0
      allow(connection).to receive(:select_value).with(/pg_cancel_backend/) do
        cancels += 1
        in_flight.push(true) && release.pop if cancels == 1
        nil # the wait ended first: undelivered
      end
      allow(connection).to receive(:select_one).and_return(observation, observation(queued_waiters: 25))
      watcher.start
      in_flight.pop
      settler = Thread.new { watcher.settle }

      expect(settler.join(0.2)).to be_nil
      release.push(true)

      expect(settler.value).to have_attributes(trip_reason: :pool_exhaustion, canceled: false)
    end

    it 'settles with the verdict the loop held when it answered, even if it moves on first', :aggregate_failures do
      piled_up = false
      allow(connection).to receive(:select_value).with(/pg_cancel_backend/).and_return(true)
      allow(connection).to receive(:select_one) { piled_up ? observation(queued_waiters: 25) : observation }
      watcher.start
      allow(watcher).to receive(:request).and_wrap_original do |original, kind|
        answer = original.call(kind)
        piled_up = true
        250.times do
          break if verdict.canceled

          sleep(0.02)
        end
        answer
      end

      expect(watcher.settle).to eq(Gitlab::Database::LockAcquisition::Protection::NO_VERDICT)
      expect(verdict.canceled).to be(true)
    end

    it 'settles with the final verdict once the loop has exited' do
      allow(connection).to receive(:select_value).with(/pg_cancel_backend/).and_return(true)
      allow(connection).to receive(:select_one).and_return(observation)
      watcher.start
      allow(connection).to receive(:select_one).and_raise(PG::UnableToSend, 'gone')
      250.times { watcher.healthy? ? sleep(0.02) : break }

      expect(watcher.settle).to have_attributes(watch_lost: true)
    end
  end

  describe 'poll resilience' do
    it 'tolerates one transient poll failure, then raises on the next', :aggregate_failures do
      allow(connection).to receive(:select_one).and_raise(PG::UnableToSend, 'boom')

      expect { watcher.send(:resilient_poll, connection) }.not_to raise_error
      expect { watcher.send(:resilient_poll, connection) }.to raise_error(PG::UnableToSend)
    end

    it 're-asserts session settings after a tolerated failure (adapter may have reconnected)', :aggregate_failures do
      allow(connection).to receive(:select_one).and_raise(PG::UnableToSend, 'boom')
      watcher.send(:resilient_poll, connection) # tolerated; session now suspect

      allow(connection).to receive(:select_one).and_return(observation)
      watcher.send(:resilient_poll, connection)

      expect(connection).to have_received(:execute).with(/SET statement_timeout = '500ms'/).at_least(:twice)
      expect(connection).to have_received(:execute).with(/SET application_name/).at_least(:twice)
    end

    it 'fails closed when re-assertion cannot restore the safety timeout', :aggregate_failures do
      allow(connection).to receive(:select_one).and_raise(PG::UnableToSend, 'boom')
      watcher.send(:resilient_poll, connection) # tolerated; session now suspect

      allow(connection).to receive(:select_one).and_return(observation)
      allow(connection).to receive(:execute).with(/SET statement_timeout/).and_raise(PG::UnableToSend, 'still bad')

      # The failed re-assertion is the second consecutive failure: it must
      # raise into the degradation path, and the poll must never run
      # without the 500ms bound.
      expect { watcher.send(:resilient_poll, connection) }.to raise_error(PG::UnableToSend)
      expect(connection).to have_received(:select_one).once
    end

    it 'resets the failure streak after a successful poll' do
      calls = 0
      allow(connection).to receive(:select_one) do
        calls += 1
        raise PG::UnableToSend, 'boom' if calls.odd?

        observation
      end

      expect { 4.times { watcher.send(:resilient_poll, connection) } }.not_to raise_error
    end
  end

  describe 'table validation' do
    it 'fails closed when a declared table does not exist' do
      allow(connection).to receive(:table_exists?).with('projects').and_return(false)

      expect { watcher.send(:prepare, connection) }
        .to raise_error(described_class::UnresolvedTablesError, /do not exist: projects/)
    end

    describe 'relation counting against a real database', :delete do
      let(:real_connection) { ActiveRecord::Base.retrieve_connection }

      def count_for(tables)
        counter = described_class.new(
          pool: pool, ddl_session: { pid: 12345, backend_start: '2026-08-21 10:00:00+00' },
          tables: tables, pool_capacity: 50, logger: logger
        )

        counter.send(:relation_count, real_connection)
      end

      it 'counts each plain table as one relation, never zero', :aggregate_failures do
        expect(count_for(%w[projects])).to eq(1)
        expect(count_for(%w[projects namespaces users])).to eq(3)
      end

      it 'expands a partitioned parent to its whole partition tree' do
        parent = real_connection.select_value(<<~SQL)
          SELECT i.inhparent::regclass::text FROM pg_inherits i
          JOIN pg_class c ON c.oid = i.inhparent
          WHERE c.relkind = 'p' LIMIT 1
        SQL

        expect(count_for([parent])).to be > 1
      end
    end
  end

  describe 'arming' do
    it 'is not healthy before it starts' do
      expect(watcher.healthy?).to be(false)
    end

    it 'degrades instead of raising when the watcher thread cannot be created', :aggregate_failures do
      allow(Thread).to receive(:new).and_raise(ThreadError, "can't create Thread")

      expect(watcher.start).to be(watcher)
      expect(watcher.degraded_reason).to eq("ThreadError: can't create Thread")
    end

    it 'blocks start until the first poll succeeds, then reports healthy', :aggregate_failures do
      allow(pool).to receive(:checkout).and_return(connection)
      allow(pool).to receive(:checkin)
      allow(connection).to receive(:select_one).and_return(observation)

      expect(watcher.start.healthy?).to be(true)

      watcher.stop

      expect(watcher.degraded_reason).to be_nil
    end

    it 'stops promptly instead of sleeping out the rest of a poll interval' do
      allow(pool).to receive(:checkout).and_return(connection)
      allow(pool).to receive(:checkin)
      allow(connection).to receive(:select_one).and_return(observation)

      watcher.start
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      watcher.stop

      expect(Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).to be < 0.5
    end

    it 'degrades instead of returning unarmed when the first poll cannot complete in time' do
      stub_const("#{described_class}::ARM_TIMEOUT_S", 0.2)
      allow(pool).to receive(:checkout) do
        sleep 0.5
        connection
      end
      allow(pool).to receive(:checkin)
      allow(connection).to receive(:select_one).and_return(observation)

      watcher.start

      expect(watcher.degraded_reason).to eq('watcher failed to arm in time')

      watcher.stop
    end
  end

  describe 'connection release' do
    it 'kills the thread and discards its connection when stop times out', :aggregate_failures do
      stub_const("#{described_class}::ARM_TIMEOUT_S", 0.3)
      stub_const("#{described_class}::JOIN_TIMEOUT_S", 0.2)
      allow(pool).to receive(:checkout).and_return(connection)
      allow(pool).to receive(:checkin)
      allow(pool).to receive(:remove)
      allow(connection).to receive(:disconnect!)
      allow(connection).to receive(:select_one) { sleep 30 } # wedged first poll

      watcher.start
      watcher.stop

      expect(pool).to have_received(:remove).with(connection)
      expect(connection).to have_received(:disconnect!)
      expect(pool).not_to have_received(:checkin)
    end

    it 'logs the stranded connection slot when the killed thread does not exit', :aggregate_failures do
      stub_const("#{described_class}::ARM_TIMEOUT_S", 0.1)
      wedged = instance_double(Thread, join: nil, kill: nil)
      allow(Thread).to receive(:new).and_return(wedged)

      watcher.start
      watcher.stop

      expect(wedged).to have_received(:kill)
      expect(logger).to have_received(:info).with(
        hash_including(message: 'Lock acquisition watcher thread survived kill; connection slot stranded')
      )
    end
  end

  describe 'degradation' do
    it 'records the failure and never raises when the watch loop dies' do
      allow(pool).to receive(:checkout).and_raise(PG::ConnectionBad, 'no slots')

      watcher.start
      watcher.stop

      expect(watcher.degraded_reason).to include('no slots')
      expect(logger).to have_received(:info).with(
        hash_including(message: 'Lock acquisition watch finished', watcher_degraded: true)
      )
    end

    it 'degrades without canceling anything when a declared table is missing', :aggregate_failures do
      unarmed = described_class.new(
        pool: pool, ddl_session: { pid: 12345, backend_start: '2026-08-21 10:00:00+00' },
        tables: %w[missing_table], pool_capacity: 50, logger: logger
      )
      allow(pool).to receive(:checkout).and_return(connection)
      allow(pool).to receive(:checkin)
      allow(connection).to receive(:table_exists?).with('missing_table').and_return(false)

      unarmed.start
      unarmed.stop

      expect(unarmed.degraded_reason).to include('UnresolvedTablesError')
      expect(logger).to have_received(:info).with(hash_including(message: 'Lock acquisition watcher degraded')).once
      expect(logger).to have_received(:info).with(
        hash_including(message: 'Lock acquisition watch finished', cancel_requested: false, trip_reason: nil)
      )
    end
  end
end
