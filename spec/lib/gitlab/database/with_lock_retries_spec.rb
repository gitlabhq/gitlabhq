# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Database::WithLockRetries do
  let(:env) { {} }
  let(:logger) { Gitlab::Database::WithLockRetries::NULL_LOGGER }
  let(:subject) { described_class.new(env: env, logger: logger, timing_configuration: timing_configuration) }

  let(:timing_configuration) do
    [
      [1.second, 1.second],
      [1.second, 1.second],
      [1.second, 1.second],
      [1.second, 1.second],
      [1.second, 1.second]
    ]
  end

  describe '#run' do
    it 'requires block' do
      expect { subject.run }.to raise_error(StandardError, 'no block given')
    end

    context 'when DISABLE_LOCK_RETRIES is set' do
      let(:env) { { 'DISABLE_LOCK_RETRIES' => 'true' } }

      it 'executes the passed block without retrying' do
        object = double

        expect(object).to receive(:method).once

        subject.run { object.method }
      end
    end

    context 'when lock retry is enabled' do
      class ActiveRecordSecond < ActiveRecord::Base
      end

      let(:lock_fiber) do
        Fiber.new do
          # Initiating a second DB connection for the lock
          conn = ActiveRecordSecond.establish_connection(Rails.configuration.database_configuration[Rails.env]).connection
          conn.transaction do
            conn.execute("LOCK TABLE #{Project.table_name} in exclusive mode")

            Fiber.yield
          end
          ActiveRecordSecond.remove_connection # force disconnect
        end
      end

      before do
        lock_fiber.resume # start the transaction and lock the table
      end

      context 'lock_fiber' do
        it 'acquires lock successfully' do
          check_exclusive_lock_query = """
            SELECT 1
            FROM pg_locks l
            JOIN pg_class t ON l.relation = t.oid
            WHERE t.relkind = 'r' AND l.mode = 'ExclusiveLock' AND t.relname = '#{Project.table_name}'
          """

          expect(ActiveRecord::Base.connection.execute(check_exclusive_lock_query).to_a).to be_present
        end
      end

      shared_examples 'retriable exclusive lock on `projects`' do
        it 'succeeds executing the given block' do
          lock_attempts = 0
          lock_acquired = false

          expect_any_instance_of(Gitlab::Database::WithLockRetries).to receive(:sleep).exactly(retry_count - 1).times # we don't sleep in the last iteration

          allow_any_instance_of(Gitlab::Database::WithLockRetries).to receive(:run_block_with_transaction).and_wrap_original do |method|
            lock_fiber.resume if lock_attempts == retry_count

            method.call
          end

          subject.run do
            lock_attempts += 1

            if lock_attempts == retry_count # we reached the last retry iteration, if we kill the thread, the last try (no lock_timeout) will succeed
              lock_fiber.resume
            end

            ActiveRecord::Base.transaction do
              ActiveRecord::Base.connection.execute("LOCK TABLE #{Project.table_name} in exclusive mode")
              lock_acquired = true
            end
          end

          expect(lock_attempts).to eq(retry_count)
          expect(lock_acquired).to eq(true)
        end
      end

      context 'after 3 iterations' do
        let(:retry_count) { 4 }

        it_behaves_like 'retriable exclusive lock on `projects`'
      end

      context 'after the retries, without setting lock_timeout' do
        let(:retry_count) { timing_configuration.size + 1 }

        it_behaves_like 'retriable exclusive lock on `projects`' do
          before do
            expect(subject).to receive(:run_block_without_lock_timeout).and_call_original
          end
        end
      end

      context 'when statement timeout is reached' do
        it 'raises QueryCanceled error' do
          lock_acquired = false
          ActiveRecord::Base.connection.execute("SET LOCAL statement_timeout='100ms'")

          expect do
            subject.run do
              ActiveRecord::Base.connection.execute("SELECT 1 FROM pg_sleep(0.11)") # 110ms
              lock_acquired = true
            end
          end.to raise_error(ActiveRecord::QueryCanceled)

          expect(lock_acquired).to eq(false)
        end
      end
    end
  end

  context 'restore local database variables' do
    it do
      expect { subject.run {} }.not_to change { ActiveRecord::Base.connection.execute("SHOW lock_timeout").to_a }
    end

    it do
      expect { subject.run {} }.not_to change { ActiveRecord::Base.connection.execute("SHOW idle_in_transaction_session_timeout").to_a }
    end
  end

  context 'casting durations correctly' do
    let(:timing_configuration) { [[0.015.seconds, 0.025.seconds], [0.015.seconds, 0.025.seconds]] } # 15ms, 25ms

    it 'executes `SET LOCAL lock_timeout` using the configured timeout value in milliseconds' do
      expect(ActiveRecord::Base.connection).to receive(:execute).with("SAVEPOINT active_record_1").and_call_original
      expect(ActiveRecord::Base.connection).to receive(:execute).with('RESET idle_in_transaction_session_timeout; RESET lock_timeout').and_call_original
      expect(ActiveRecord::Base.connection).to receive(:execute).with("SET LOCAL lock_timeout TO '15ms'").and_call_original
      expect(ActiveRecord::Base.connection).to receive(:execute).with("RELEASE SAVEPOINT active_record_1").and_call_original

      subject.run { }
    end

    it 'calls `sleep` after the first iteration fails, using the configured sleep time' do
      expect(subject).to receive(:run_block_with_transaction).and_raise(ActiveRecord::LockWaitTimeout).twice
      expect(subject).to receive(:sleep).with(0.025)

      subject.run { }
    end
  end
end
