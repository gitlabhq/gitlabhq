# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::WithHeldLockRetries, feature_category: :database do
  let(:connection) { ActiveRecord::Base.retrieve_connection }

  describe '#initialize' do
    it 'rejects a custom timing configuration' do
      expect do
        described_class.new(
          connection: connection, tables: [Project.table_name], timing_configuration: [[1.second, 1.second]]
        )
      end.to raise_error(ArgumentError, /timing_configuration/)
    end
  end

  describe '#run' do
    context 'for hold mode' do
      let(:logger) { instance_spy(Gitlab::JsonLogger) }
      let(:env) { {} }

      let(:hold_kwargs) { {} }

      subject(:lock_retries) do
        described_class.new(
          connection: connection, env: env, logger: logger,
          tables: [Project.table_name], **hold_kwargs
        )
      end

      def verdict(**attrs)
        Gitlab::Database::LockAcquisition::Protection::NO_VERDICT.with(**attrs)
      end

      # A demoted run uses WithLockRetries' own timings, whatever they are;
      # anything below the 1s canary means hold timing is off.
      def default_ladder_timeout
        a_value < described_class::HOLD_TIMING_CONFIGURATION.first.first.in_milliseconds
      end

      it 'uses the hold timing configuration and runs the watcher around the block', :aggregate_failures do
        expect_next_instance_of(Gitlab::Database::LockAcquisition::Watcher) do |watcher|
          allow(watcher).to receive(:begin_attempt)
          expect(watcher).to receive(:start).and_return(watcher)
          allow(watcher).to receive(:healthy?).and_return(true)
          expect(watcher).to receive(:stop)
        end

        lock_retries.run(raise_on_exhaustion: true) { connection.execute('SELECT 1') }

        expect(logger).to have_received(:info).with(
          hash_including(message: 'Lock timeout is set', lock_timeout_in_ms: 1000)
        )
      end

      it 'requires a block before starting a watcher', :aggregate_failures do
        expect(Gitlab::Database::LockAcquisition::Watcher).not_to receive(:new)

        expect { lock_retries.run(raise_on_exhaustion: true) }.to raise_error(RuntimeError, 'no block given')
      end

      it 'raises WaiterPileupError carrying the trip reason, without retrying', :aggregate_failures do
        expect_next_instance_of(Gitlab::Database::LockAcquisition::Watcher) do |watcher|
          allow(watcher).to receive(:begin_attempt)
          allow(watcher).to receive_messages(
            start: watcher, stop: nil, healthy?: true,
            settle: verdict(trip_reason: :accumulated_wait, canceled: true)
          )
        end

        attempts = 0

        expect do
          lock_retries.run(raise_on_exhaustion: true) do
            attempts += 1
            raise ActiveRecord::QueryCanceled, 'canceling statement due to user request'
          end
        end.to raise_error(described_class::WaiterPileupError) { |error|
          expect(error.reason).to eq(:accumulated_wait)
        }

        expect(attempts).to eq(1)
        expect(logger).to have_received(:info)
          .with(hash_including(message: 'Lock acquisition attempt blocked'))
      end

      it 're-raises a QueryCanceled the watcher did not deliver, even one it had decided on' do
        expect_next_instance_of(Gitlab::Database::LockAcquisition::Watcher) do |watcher|
          allow(watcher).to receive(:begin_attempt)
          allow(watcher).to receive_messages(
            start: watcher, stop: nil, healthy?: true, settle: verdict(trip_reason: :pool_exhaustion)
          )
        end

        expect do
          lock_retries.run(raise_on_exhaustion: true) do
            raise ActiveRecord::QueryCanceled, 'canceling statement due to statement timeout'
          end
        end.to raise_error(ActiveRecord::QueryCanceled)
      end

      it 'classifies by the watcher flags regardless of the message language', :aggregate_failures do
        expect_next_instance_of(Gitlab::Database::LockAcquisition::Watcher) do |watcher|
          allow(watcher).to receive(:begin_attempt)
          allow(watcher).to receive_messages(
            start: watcher, stop: nil, healthy?: true,
            settle: verdict(trip_reason: :pool_exhaustion, canceled: true)
          )
        end

        expect do
          lock_retries.run(raise_on_exhaustion: true) do
            # A delivered cancel on a non-English lc_messages instance.
            raise ActiveRecord::QueryCanceled, 'Anweisung wegen Benutzeranforderung abgebrochen'
          end
        end.to raise_error(described_class::WaiterPileupError) { |error|
          expect(error.reason).to eq(:pool_exhaustion)
        }
      end

      it 'raises WatchLostError when a delivered watch-loss lost the race to lock_timeout', :aggregate_failures do
        expect_next_instance_of(Gitlab::Database::LockAcquisition::Watcher) do |watcher|
          allow(watcher).to receive(:begin_attempt)
          allow(watcher).to receive_messages(
            start: watcher, stop: nil, healthy?: true,
            settle: verdict(watch_lost: true)
          )
        end

        attempts = 0

        expect do
          lock_retries.run(raise_on_exhaustion: true) do
            attempts += 1
            raise ActiveRecord::LockWaitTimeout
          end
        end.to raise_error(described_class::WatchLostError)

        expect(attempts).to eq(1)
        expect(logger).to have_received(:info)
          .with(hash_including(message: 'Lock acquisition attempt blocked', current_iteration: 1))
      end

      it 'honors the watcher decision when the attempt lock_timeout beat its delivery', :aggregate_failures do
        expect_next_instance_of(Gitlab::Database::LockAcquisition::Watcher) do |watcher|
          allow(watcher).to receive(:begin_attempt)
          allow(watcher).to receive_messages(
            start: watcher, stop: nil, healthy?: true, settle: verdict(trip_reason: :table_too_hot)
          )
        end

        attempts = 0

        expect do
          lock_retries.run(raise_on_exhaustion: true) do
            attempts += 1
            raise ActiveRecord::LockWaitTimeout
          end
        end.to raise_error(described_class::WaiterPileupError) { |error| expect(error.reason).to eq(:table_too_hot) }

        expect(attempts).to eq(1)
      end

      it 'raises WaiterPileupError for a trip on the final attempt instead of exhausting', :aggregate_failures do
        expect_next_instance_of(Gitlab::Database::LockAcquisition::Watcher) do |watcher|
          allow(watcher).to receive(:begin_attempt)
          allow(watcher).to receive_messages(start: watcher, stop: nil, healthy?: true)
          allow(watcher).to receive(:settle)
            .and_return(verdict, verdict, verdict, verdict(trip_reason: :accumulated_wait))
        end
        allow(lock_retries).to receive(:sleep)

        attempts = 0

        expect do
          lock_retries.run(raise_on_exhaustion: true) do
            attempts += 1
            raise ActiveRecord::LockWaitTimeout
          end
        end.to raise_error(described_class::WaiterPileupError) { |error| expect(error.reason).to eq(:accumulated_wait) }

        expect(attempts).to eq(4)
        expect(logger).to have_received(:info)
          .with(hash_including(message: 'Lock timeout is set', current_iteration: 2, lock_timeout_in_ms: 7000))
      end

      it 'retries a held attempt that PostgreSQL ended as a deadlock victim', :aggregate_failures do
        expect_next_instance_of(Gitlab::Database::LockAcquisition::Watcher) do |watcher|
          allow(watcher).to receive(:begin_attempt)
          allow(watcher).to receive_messages(start: watcher, stop: nil, healthy?: true, settle: verdict)
        end
        allow(lock_retries).to receive(:sleep)

        attempts = 0

        lock_retries.run(raise_on_exhaustion: true) do
          attempts += 1
          raise ActiveRecord::LockWaitTimeout if attempts == 1
          raise ActiveRecord::Deadlocked, 'deadlock detected' if attempts == 2
        end

        expect(attempts).to eq(3)
        expect(logger).to have_received(:info)
          .with(hash_including(message: 'Held attempt ended in a deadlock', current_iteration: 2))
        expect(logger).to have_received(:info)
          .with(hash_including(message: 'Lock acquisition attempt blocked', current_iteration: 2))
      end

      it 'honors the watcher decision when a held attempt ends in a deadlock' do
        expect_next_instance_of(Gitlab::Database::LockAcquisition::Watcher) do |watcher|
          allow(watcher).to receive(:begin_attempt)
          allow(watcher).to receive_messages(
            start: watcher, stop: nil, healthy?: true, settle: verdict(trip_reason: :accumulated_wait)
          )
        end

        expect do
          lock_retries.run(raise_on_exhaustion: true) { raise ActiveRecord::Deadlocked, 'deadlock detected' }
        end.to raise_error(described_class::WaiterPileupError) { |error| expect(error.reason).to eq(:accumulated_wait) }
      end

      it 'exhausts with a census when the final held attempt ends in a deadlock', :aggregate_failures do
        expect_next_instance_of(Gitlab::Database::LockAcquisition::Watcher) do |watcher|
          allow(watcher).to receive(:begin_attempt)
          allow(watcher).to receive_messages(start: watcher, stop: nil, healthy?: true, settle: verdict)
        end
        allow(lock_retries).to receive(:sleep)

        attempts = 0

        expect do
          lock_retries.run(raise_on_exhaustion: true) do
            attempts += 1
            raise ActiveRecord::Deadlocked, 'deadlock detected' if attempts == 4

            raise ActiveRecord::LockWaitTimeout
          end
        end.to raise_error(described_class::AttemptsExhaustedError) { |error|
          expect(error.cause).to be_a(ActiveRecord::LockWaitTimeout)
          expect(error.cause.cause).to be_a(ActiveRecord::Deadlocked)
        }

        expect(attempts).to eq(4)
        expect(logger).to have_received(:info)
          .with(hash_including(message: 'Lock acquisition attempt blocked', current_iteration: 4, exhausted: true))
      end

      it 'stops instead of holding an attempt on a backend the watcher is not watching', :aggregate_failures do
        expect_next_instance_of(Gitlab::Database::LockAcquisition::Watcher) do |watcher|
          expect(watcher).to receive(:begin_attempt).twice
          allow(watcher).to receive_messages(start: watcher, stop: nil, healthy?: true, settle: verdict)
        end
        allow(lock_retries).to receive(:sleep)
        watched_pid = connection.select_value('SELECT pg_backend_pid()')
        allow(connection).to receive(:select_value).and_call_original
        allow(connection).to receive(:select_value).with('SELECT pg_backend_pid()')
          .and_return(watched_pid, watched_pid + 1)

        attempts = 0

        expect do
          lock_retries.run(raise_on_exhaustion: true) do
            attempts += 1
            raise ActiveRecord::LockWaitTimeout
          end
        end.to raise_error(described_class::WatchLostError)

        expect(attempts).to eq(1)
        expect(logger).to have_received(:info).with(hash_including(
          message: 'Hold session moved to a new backend', watched_pid: watched_pid, backend_pid: watched_pid + 1
        ))
      end

      it 'raises WatchLostError without retrying when the watcher canceled after losing watch', :aggregate_failures do
        expect_next_instance_of(Gitlab::Database::LockAcquisition::Watcher) do |watcher|
          allow(watcher).to receive(:begin_attempt)
          allow(watcher).to receive_messages(
            start: watcher, stop: nil, healthy?: true,
            settle: verdict(watch_lost: true)
          )
        end

        attempts = 0

        expect do
          lock_retries.run(raise_on_exhaustion: true) do
            attempts += 1
            raise ActiveRecord::QueryCanceled, 'canceling statement due to user request'
          end
        end.to raise_error(described_class::WatchLostError)

        expect(attempts).to eq(1)
        expect(logger).to have_received(:info)
          .with(hash_including(message: 'Lock acquisition attempt blocked', current_iteration: 1))
      end

      it 'does not log an exhausted census when the block raises AttemptsExhaustedError itself', :aggregate_failures do
        expect_next_instance_of(Gitlab::Database::LockAcquisition::Watcher) do |watcher|
          allow(watcher).to receive(:begin_attempt)
          allow(watcher).to receive_messages(start: watcher, stop: nil, healthy?: true)
        end

        expect do
          lock_retries.run(raise_on_exhaustion: true) { raise described_class::AttemptsExhaustedError, 'inner' }
        end.to raise_error(described_class::AttemptsExhaustedError, 'inner')

        expect(logger).not_to have_received(:info).with(hash_including(exhausted: true))
      end

      context 'when raise_on_exhaustion is not set' do
        it 'raises ArgumentError instead of silently running unheld', :aggregate_failures do
          expect(Gitlab::Database::LockAcquisition::Watcher).not_to receive(:new)

          expect { lock_retries.run { connection.execute('SELECT 1') } }
            .to raise_error(ArgumentError, /raise_on_exhaustion/)
        end

        context 'when DISABLE_LOCK_RETRIES is set' do
          let(:env) { { 'DISABLE_LOCK_RETRIES' => 'true' } }

          it 'still raises: the caller contract is unconditional' do
            expect { lock_retries.run { connection.execute('SELECT 1') } }
              .to raise_error(ArgumentError, /raise_on_exhaustion/)
          end
        end
      end

      context 'when no tables are declared' do
        let(:hold_kwargs) { { tables: [] } }

        it 'falls back to default timing and logs the reason', :aggregate_failures do
          expect(Gitlab::Database::LockAcquisition::Watcher).not_to receive(:new)

          lock_retries.run(raise_on_exhaustion: true) { connection.execute('SELECT 1') }

          expect(logger).to have_received(:info).with(
            hash_including(message: 'Hold mode requested but unavailable, using default timing', tables: [])
          )
          expect(logger).to have_received(:info).with(
            hash_including(message: 'Lock timeout is set', lock_timeout_in_ms: default_ladder_timeout)
          )
        end

        it 'retries a lock timeout on the default ladder without a watcher, census, or demotion', :aggregate_failures do
          expect(Gitlab::Database::LockAcquisition::BlockerCensus).not_to receive(:capture)
          allow(lock_retries).to receive(:sleep)

          attempts = 0

          lock_retries.run(raise_on_exhaustion: true) do
            attempts += 1
            raise ActiveRecord::LockWaitTimeout if attempts == 1
          end

          expect(attempts).to eq(2)
          expect(logger).not_to have_received(:info).with(hash_including(message: 'Hold mode demoted'))
        end

        it 'does not retry a deadlock, as the default ladder does not', :aggregate_failures do
          attempts = 0

          expect do
            lock_retries.run(raise_on_exhaustion: true) do
              attempts += 1
              raise ActiveRecord::Deadlocked, 'deadlock detected' if attempts == 1
            end
          end.to raise_error(ActiveRecord::Deadlocked)

          expect(attempts).to eq(1)
        end
      end

      context 'when DISABLE_LOCK_RETRIES is set with tables declared' do
        let(:env) do
          { 'DISABLE_LOCK_RETRIES' => 'true' }
        end

        it 'bypasses hold mode, runs the block once, and logs the bypass', :aggregate_failures do
          expect(Gitlab::Database::LockAcquisition::Watcher).not_to receive(:new)

          runs = 0

          lock_retries.run(raise_on_exhaustion: true) { runs += 1 }

          expect(runs).to eq(1)
          expect(logger).to have_received(:info).with(hash_including(
            message: 'DISABLE_LOCK_RETRIES environment variable is true, bypassing hold mode',
            tables: [Project.table_name]
          ))
        end
      end

      it 'logs a failed RESET instead of masking the attempt error, and still stops the watcher',
        :aggregate_failures do
        stopped = nil
        expect_next_instance_of(Gitlab::Database::LockAcquisition::Watcher) do |watcher|
          stopped = watcher
          allow(watcher).to receive(:begin_attempt)
          allow(watcher).to receive_messages(start: watcher, stop: nil, healthy?: true, settle: verdict)
        end
        allow(connection).to receive(:execute).and_call_original
        allow(connection).to receive(:execute).with(/\ARESET/)
          .and_raise(ActiveRecord::StatementInvalid, 'current transaction is aborted')

        expect do
          lock_retries.run(raise_on_exhaustion: true) do
            raise ActiveRecord::QueryCanceled, 'canceling statement due to statement timeout'
          end
        end.to raise_error(ActiveRecord::QueryCanceled)

        expect(logger).to have_received(:info).with(hash_including(
          message: 'Failed to reset db settings', Labkit::Fields::ERROR_TYPE => 'ActiveRecord::StatementInvalid'
        ))
        expect(stopped).to have_received(:stop)
      end

      it 'keeps the typed error when the connection is gone by the RESET', :aggregate_failures do
        expect_next_instance_of(Gitlab::Database::LockAcquisition::Watcher) do |watcher|
          allow(watcher).to receive(:begin_attempt)
          allow(watcher).to receive_messages(
            start: watcher, stop: nil, healthy?: true, settle: verdict(trip_reason: :accumulated_wait, canceled: true)
          )
        end
        allow(connection).to receive(:execute).and_call_original
        allow(connection).to receive(:execute).with(/\ARESET/)
          .and_raise(ActiveRecord::ConnectionNotEstablished, 'connection is closed')

        expect do
          lock_retries.run(raise_on_exhaustion: true) do
            raise ActiveRecord::QueryCanceled, 'canceling statement due to user request'
          end
        end.to raise_error(described_class::WaiterPileupError) { |error| expect(error.reason).to eq(:accumulated_wait) }

        expect(logger).to have_received(:info).with(hash_including(
          message: 'Failed to reset db settings', Labkit::Fields::ERROR_TYPE => 'ActiveRecord::ConnectionNotEstablished'
        )).at_least(:once)
      end

      it 'converts a stalled handoff into WatchLostError before the attempt runs', :aggregate_failures do
        stalled = nil
        expect_next_instance_of(Gitlab::Database::LockAcquisition::Watcher) do |watcher|
          stalled = watcher
          allow(watcher).to receive_messages(start: watcher, stop: nil, healthy?: true)
          allow(watcher).to receive(:begin_attempt)
            .and_raise(Gitlab::Database::LockAcquisition::Watcher::SupervisionStalledError)
        end

        ran = false

        expect { lock_retries.run(raise_on_exhaustion: true) { ran = true } }
          .to raise_error(described_class::WatchLostError)

        expect(ran).to be(false)
        expect(stalled).to have_received(:stop)
      end

      it 'converts a watcher that stops answering at the end of an attempt into WatchLostError' do
        expect_next_instance_of(Gitlab::Database::LockAcquisition::Watcher) do |watcher|
          allow(watcher).to receive(:begin_attempt)
          allow(watcher).to receive_messages(start: watcher, stop: nil, healthy?: true)
          allow(watcher).to receive(:settle).and_raise(Gitlab::Database::LockAcquisition::Watcher::SupervisionStalledError)
        end

        expect { lock_retries.run(raise_on_exhaustion: true) { raise ActiveRecord::LockWaitTimeout } }
          .to raise_error(described_class::WatchLostError)
      end

      context 'when reading max_connections fails' do
        it 'demotes to the default ladder instead of failing the run', :aggregate_failures do
          allow(connection).to receive(:select_value).and_call_original
          allow(connection).to receive(:select_value)
            .with('SHOW max_connections').and_raise(ActiveRecord::StatementInvalid, 'boom')

          lock_retries.run(raise_on_exhaustion: true) { connection.execute('SELECT 1') }

          expect(logger).to have_received(:info).with(
            hash_including(message: 'Hold mode demoted')
          )
          expect(logger).to have_received(:info).with(
            hash_including(message: 'Lock timeout is set', lock_timeout_in_ms: default_ladder_timeout)
          )
        end
      end

      it 'stops a watcher that was interrupted while it armed', :aggregate_failures do
        interrupted = nil
        expect_next_instance_of(Gitlab::Database::LockAcquisition::Watcher) do |watcher|
          interrupted = watcher
          allow(watcher).to receive(:start).and_raise(Interrupt)
          allow(watcher).to receive(:stop)
        end

        expect { lock_retries.run(raise_on_exhaustion: true) { connection.execute('SELECT 1') } }
          .to raise_error(Interrupt)

        expect(interrupted).to have_received(:stop)
      end

      it 'wires the server capacity into the watcher' do
        allow(connection).to receive(:select_value).and_call_original
        allow(connection).to receive(:select_value)
          .with('SHOW max_connections').and_return('123')

        watcher = instance_double(
          Gitlab::Database::LockAcquisition::Watcher, stop: nil, healthy?: true, begin_attempt: nil
        )
        allow(watcher).to receive(:start).and_return(watcher)
        expect(Gitlab::Database::LockAcquisition::Watcher).to receive(:new)
          .with(hash_including(pool_capacity: 123))
          .and_return(watcher)

        lock_retries.run(raise_on_exhaustion: true) { connection.execute('SELECT 1') }
      end

      it 'tells the watcher about every attempt', :aggregate_failures do
        boundary_watcher = nil
        expect_next_instance_of(Gitlab::Database::LockAcquisition::Watcher) do |watcher|
          allow(watcher).to receive(:begin_attempt)
          boundary_watcher = watcher
          allow(watcher).to receive_messages(
            start: watcher, stop: nil, settle: verdict
          )
          allow(watcher).to receive(:healthy?).and_return(true)
        end
        allow(lock_retries).to receive(:sleep)

        attempts = 0
        lock_retries.run(raise_on_exhaustion: true) do
          attempts += 1
          raise ActiveRecord::LockWaitTimeout if attempts == 1

          connection.execute('SELECT 1')
        end

        expect(attempts).to eq(2)
        expect(boundary_watcher).to have_received(:begin_attempt).twice
      end

      context 'when the watcher fails to start' do
        it 'falls back to the default ladder instead of failing the run', :aggregate_failures do
          allow(Gitlab::Database::LockAcquisition::Watcher)
            .to receive(:new).and_raise(PG::ConnectionBad, 'no slots')

          lock_retries.run(raise_on_exhaustion: true) { connection.execute('SELECT 1') }

          expect(logger).to have_received(:info).with(
            hash_including(message: 'Hold mode demoted')
          )
          expect(logger).to have_received(:info).with(
            hash_including(message: 'Lock timeout is set', lock_timeout_in_ms: default_ladder_timeout)
          )
        end
      end

      context 'when the watcher fails to arm' do
        it 'falls back to the default ladder', :aggregate_failures do
          expect_next_instance_of(Gitlab::Database::LockAcquisition::Watcher) do |watcher|
            expect(watcher).not_to receive(:begin_attempt)
            expect(watcher).to receive(:stop).once
            allow(watcher).to receive_messages(
              start: watcher, healthy?: false, degraded_reason: 'watcher failed to arm in time'
            )
          end

          lock_retries.run(raise_on_exhaustion: true) { connection.execute('SELECT 1') }

          expect(logger).to have_received(:info).with(
            hash_including(demotion_reason: 'watcher failed to arm: watcher failed to arm in time')
          )
          expect(logger).to have_received(:info).with(
            hash_including(message: 'Lock timeout is set', lock_timeout_in_ms: default_ladder_timeout)
          )
        end
      end

      context 'when the watcher dies during the retry sleep' do
        it 'continues on the default ladder instead of holding unwatched', :aggregate_failures do
          healthy = true
          expect_next_instance_of(Gitlab::Database::LockAcquisition::Watcher) do |watcher|
            expect(watcher).to receive(:begin_attempt).once
            expect(watcher).to receive(:stop).once
            allow(watcher).to receive_messages(start: watcher, settle: verdict)
            allow(watcher).to receive(:healthy?) { healthy }
          end
          allow(lock_retries).to receive(:sleep) { healthy = false }

          attempts = 0
          lock_retries.run(raise_on_exhaustion: true) do
            attempts += 1
            raise ActiveRecord::LockWaitTimeout if attempts == 1

            connection.execute('SELECT 1')
          end

          expect(logger).to have_received(:info).with(
            hash_including(demotion_reason: 'watcher unhealthy')
          )
          expect(logger).to have_received(:info).with(
            hash_including(
              message: 'Lock timeout is set', current_iteration: 2, lock_timeout_in_ms: default_ladder_timeout
            )
          )
        end

        it 'demotes when the backend was also replaced, instead of raising WatchLostError', :aggregate_failures do
          healthy = true
          expect_next_instance_of(Gitlab::Database::LockAcquisition::Watcher) do |watcher|
            expect(watcher).to receive(:begin_attempt).once
            expect(watcher).to receive(:stop).once
            allow(watcher).to receive_messages(start: watcher, settle: verdict)
            allow(watcher).to receive(:healthy?) { healthy }
          end
          allow(lock_retries).to receive(:sleep) { healthy = false }
          watched_pid = connection.select_value('SELECT pg_backend_pid()')
          allow(connection).to receive(:select_value).and_call_original
          allow(connection).to receive(:select_value).with('SELECT pg_backend_pid()')
            .and_return(watched_pid, watched_pid + 1)

          attempts = 0
          lock_retries.run(raise_on_exhaustion: true) do
            attempts += 1
            raise ActiveRecord::LockWaitTimeout if attempts == 1
          end

          expect(attempts).to eq(2)
          expect(logger).to have_received(:info).with(hash_including(demotion_reason: 'watcher unhealthy'))
        end

        it 'does not retry a deadlock after the demotion, as the default ladder does not', :aggregate_failures do
          healthy = true
          expect_next_instance_of(Gitlab::Database::LockAcquisition::Watcher) do |watcher|
            expect(watcher).to receive(:begin_attempt).once
            allow(watcher).to receive_messages(start: watcher, stop: nil, settle: verdict)
            allow(watcher).to receive(:healthy?) { healthy }
          end
          allow(lock_retries).to receive(:sleep) { healthy = false }

          attempts = 0

          expect do
            lock_retries.run(raise_on_exhaustion: true) do
              attempts += 1
              raise ActiveRecord::LockWaitTimeout if attempts == 1

              raise ActiveRecord::Deadlocked, 'deadlock detected'
            end
          end.to raise_error(ActiveRecord::Deadlocked)

          expect(attempts).to eq(2)
          expect(logger).not_to have_received(:info).with(hash_including(message: 'Held attempt ended in a deadlock'))
        end
      end

      context 'when the watcher dies during the reset between attempts' do
        it 'demotes before the next attempt instead of starting it unwatched', :aggregate_failures do
          healthy = true
          expect_next_instance_of(Gitlab::Database::LockAcquisition::Watcher) do |watcher|
            expect(watcher).to receive(:begin_attempt).once
            allow(watcher).to receive_messages(start: watcher, stop: nil, settle: verdict)
            allow(watcher).to receive(:healthy?) { healthy }
          end
          allow(lock_retries).to receive(:sleep)
          allow(connection).to receive(:execute).and_wrap_original do |original, *args, **kwargs|
            healthy = false if args.first.to_s.start_with?('RESET')
            original.call(*args, **kwargs)
          end

          attempts = 0
          lock_retries.run(raise_on_exhaustion: true) do
            attempts += 1
            raise ActiveRecord::LockWaitTimeout if attempts == 1
          end

          expect(attempts).to eq(2)
          expect(logger).to have_received(:info).with(
            hash_including(demotion_reason: 'watcher unhealthy')
          )
          expect(logger).to have_received(:info).with(
            hash_including(
              message: 'Lock timeout is set', current_iteration: 2, lock_timeout_in_ms: default_ladder_timeout
            )
          )
        end
      end

      context 'with a real conflicting lock and real waiters', :delete do
        def raw_connection_params
          config = ActiveRecord::Base.connection_db_config.configuration_hash

          {
            host: config[:host],
            port: config[:port],
            dbname: config[:database],
            user: config[:username],
            password: config[:password]
          }.compact
        end

        it 'cancels its own wait via the watcher and raises WaiterPileupError', :aggregate_failures do
          blocker = ActiveRecord::Base.connection_pool.checkout
          waiters = []
          ddl_pid = connection.select_value('SELECT pg_backend_pid()')
          long_attempt_started = Queue.new
          attempts = 0
          hold_attempts = described_class::HOLD_TIMING_CONFIGURATION.size

          begin
            blocker.begin_db_transaction
            blocker.execute("LOCK TABLE #{Project.table_name} IN EXCLUSIVE MODE")

            # Three sessions arrive AFTER the migration starts waiting, so
            # they queue behind its lock request and are billed to it
            # (waiters already blocked before we arrived are not counted).
            # send_query keeps them non-blocking for this test process.
            spawner = Thread.new do
              waiters.concat(Array.new(3) { PG.connect(**raw_connection_params) })
              long_attempt_started.pop(timeout: 15)
              250.times do
                break if waiters.first.exec("SELECT 1 FROM pg_locks WHERE pid = #{ddl_pid} AND NOT granted").ntuples > 0

                sleep(0.02)
              end
              waiters.each { |waiter| waiter.send_query("SELECT id FROM #{Project.table_name} LIMIT 1 FOR UPDATE") }
            end

            expect do
              lock_retries.run(raise_on_exhaustion: true) do
                attempts += 1
                raise "ran past the hold ladder (attempt #{attempts})" if attempts > hold_attempts

                long_attempt_started.push(true) if attempts == 2 # the first long hold attempt
                connection.execute("LOCK TABLE #{Project.table_name} IN ACCESS EXCLUSIVE MODE")
              end
            end.to raise_error(described_class::WaiterPileupError) { |error|
              expect(error.cause).to be_a(ActiveRecord::QueryCanceled)
            }

            spawner.join

            expect(logger).to have_received(:info).with(
              hash_including(message: 'Lock acquisition watcher canceling own session', signalled: true)
            )
          ensure
            waiters.each do |waiter|
              waiter.cancel
              waiter.close
            rescue PG::Error
              nil
            end
            blocker.rollback_db_transaction
            ActiveRecord::Base.connection_pool.checkin(blocker)
          end
        end
      end
    end

    context 'for blocker census logging', :delete do
      let(:logger) { instance_spy(Gitlab::JsonLogger) }
      let(:env) { {} }
      let(:blocker_connection) { ActiveRecord::Base.connection_pool.checkout }

      subject(:lock_retries) do
        described_class.new(
          connection: connection, env: env, logger: logger,
          tables: [Project.table_name]
        )
      end

      around do |example|
        blocker_connection.begin_db_transaction
        blocker_connection.execute("LOCK TABLE #{Project.table_name} IN EXCLUSIVE MODE")

        example.run
      ensure
        blocker_connection.rollback_db_transaction
        ActiveRecord::Base.connection_pool.checkin(blocker_connection)
      end

      before do
        expect_next_instance_of(Gitlab::Database::LockAcquisition::Watcher) do |watcher|
          allow(watcher).to receive(:begin_attempt)
          allow(watcher).to receive_messages(
            start: watcher, stop: nil, healthy?: true, settle: Gitlab::Database::LockAcquisition::Protection::NO_VERDICT
          )
        end
        allow(lock_retries).to receive(:sleep)
      end

      def run_until_exhaustion
        expect do
          lock_retries.run(raise_on_exhaustion: true) { raise ActiveRecord::LockWaitTimeout }
        end.to raise_error(described_class::AttemptsExhaustedError)
      end

      it 'logs the census on every failed attempt and on exhaustion', :aggregate_failures do
        run_until_exhaustion

        expect(logger).to have_received(:info)
          .with(hash_including(message: 'Lock acquisition attempt blocked', current_iteration: 1, exhausted: false))
        expect(logger).to have_received(:info)
          .with(hash_including(message: 'Lock acquisition attempt blocked', current_iteration: 4, exhausted: true))
      end

      it 'includes the blocker census and the tables in the payload', :aggregate_failures do
        blocker_pid = blocker_connection.select_value('SELECT pg_backend_pid()')

        run_until_exhaustion

        expect(logger).to have_received(:info).with(
          hash_including(tables: [Project.table_name], blockers: include(hash_including('pid' => blocker_pid)))
        ).at_least(:once)
      end

      context 'when the census itself fails' do
        it 'logs the error payload and still retries to exhaustion', :aggregate_failures do
          allow(Gitlab::Database::LockAcquisition::BlockerCensus)
            .to receive(:capture).and_return({ census_error: 'boom' })

          run_until_exhaustion

          expect(logger).to have_received(:info)
            .with(hash_including(message: 'Lock acquisition attempt blocked', census_error: 'boom'))
            .at_least(:once)
        end
      end
    end
  end
end
