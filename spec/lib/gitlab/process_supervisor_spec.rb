# frozen_string_literal: true

require_relative '../../../lib/gitlab/process_supervisor'

RSpec.describe Gitlab::ProcessSupervisor, feature_category: :cloud_connector do
  let(:health_check_interval_seconds) { 0.1 }
  let(:check_terminate_interval_seconds) { 1 }
  let(:forwarded_signals) { [] }
  let(:term_signals) { [] }
  let(:process_ids) { [spawn_process, spawn_process] }

  def spawn_process
    Process.spawn('while true; do sleep 1; done').tap do |pid|
      Process.detach(pid)
    end
  end

  subject(:supervisor) do
    described_class.new(
      health_check_interval_seconds: health_check_interval_seconds,
      check_terminate_interval_seconds: check_terminate_interval_seconds,
      terminate_timeout_seconds: 1 + check_terminate_interval_seconds,
      forwarded_signals: forwarded_signals,
      term_signals: term_signals
    )
  end

  after do
    process_ids.each do |pid|
      Process.kill('KILL', pid)
    rescue Errno::ESRCH
      # Ignore if a process wasn't actually alive.
    end

    supervisor.stop
  end

  describe '#supervise' do
    context 'while supervised processes are alive' do
      it 'does not invoke callback' do
        expect(Gitlab::ProcessManagement.all_alive?(process_ids)).to be(true)
        pids_killed = []

        supervisor.supervise(process_ids) do |dead_pids|
          pids_killed += dead_pids
          []
        end

        # Wait several times the poll frequency of the supervisor.
        sleep health_check_interval_seconds * 10

        expect(pids_killed).to be_empty
        expect(Gitlab::ProcessManagement.all_alive?(process_ids)).to be(true)
      end
    end

    context 'when a supervised process dies' do
      it 'triggers callback with the dead PIDs and adds new PIDs to supervised PIDs' do
        expect(Gitlab::ProcessManagement.all_alive?(process_ids)).to be(true)
        pids_killed = []

        supervisor.supervise(process_ids) do |dead_pids|
          pids_killed += dead_pids
          [42] # Fake starting a new process in place of the terminated one.
        end

        # Terminate a supervised process.
        Process.kill('TERM', process_ids.first)

        await_condition(sleep_sec: health_check_interval_seconds) do
          pids_killed.include?(process_ids.first)
        end

        expect(Gitlab::ProcessManagement.process_alive?(process_ids.first)).to be(false)
        expect(Gitlab::ProcessManagement.process_alive?(process_ids.last)).to be(true)
        expect(supervisor.supervised_pids).to match_array([process_ids.last, 42])
      end

      it 'deduplicates PIDs returned from callback' do
        expect(Gitlab::ProcessManagement.all_alive?(process_ids)).to be(true)
        pids_killed = []

        supervisor.supervise(process_ids) do |dead_pids|
          pids_killed += dead_pids
          # Fake a new process having the same pid as one that was just terminated.
          [process_ids.last]
        end

        # Terminate a supervised process.
        Process.kill('TERM', process_ids.first)

        await_condition(sleep_sec: health_check_interval_seconds) do
          pids_killed.include?(process_ids.first)
        end

        expect(supervisor.supervised_pids).to contain_exactly(process_ids.last)
      end

      it 'accepts single PID returned from callback' do
        expect(Gitlab::ProcessManagement.all_alive?(process_ids)).to be(true)
        pids_killed = []

        supervisor.supervise(process_ids) do |dead_pids|
          pids_killed += dead_pids
          42
        end

        # Terminate a supervised process.
        Process.kill('TERM', process_ids.first)

        await_condition(sleep_sec: health_check_interval_seconds) do
          pids_killed.include?(process_ids.first)
        end

        expect(supervisor.supervised_pids).to contain_exactly(42, process_ids.last)
      end

      context 'but supervisor has entered shutdown' do
        it 'does not trigger callback again' do
          expect(Gitlab::ProcessManagement.all_alive?(process_ids)).to be(true)
          callback_count = 0

          supervisor.supervise(process_ids) do |dead_pids|
            callback_count += 1

            Thread.new { supervisor.shutdown }

            [42]
          end

          # Terminate the supervised processes to trigger more than 1 callback.
          Process.kill('TERM', process_ids.first)
          Process.kill('TERM', process_ids.last)

          await_condition(sleep_sec: health_check_interval_seconds * 3) do
            supervisor.alive == false
          end

          # Since we shut down the supervisor during the first callback, it should not
          # be called anymore.
          expect(callback_count).to eq(1)
        end
      end
    end

    context 'signal handling' do
      before do
        allow(supervisor).to receive(:sleep)
        allow(Gitlab::ProcessManagement).to receive(:trap_signals)
        allow(Gitlab::ProcessManagement).to receive(:all_alive?).and_return(false)
        allow(Gitlab::ProcessManagement).to receive(:signal_processes).with(process_ids, anything)
      end

      context 'termination signals' do
        let(:term_signals) { %i[INT TERM] }

        context 'when TERM results in timely shutdown of processes' do
          it 'forwards them to observed processes without waiting for grace period to expire' do
            allow(Gitlab::ProcessManagement).to receive(:any_alive?).and_return(false)

            expect(Gitlab::ProcessManagement).to receive(:trap_signals).ordered.with(%i[INT TERM]).and_yield(:TERM)
            expect(Gitlab::ProcessManagement).to receive(:signal_processes).ordered.with(process_ids, :TERM)
            expect(supervisor).not_to receive(:sleep).with(check_terminate_interval_seconds)

            supervisor.supervise(process_ids) { [] }
          end
        end

        context 'when TERM does not result in timely shutdown of processes' do
          it 'issues a KILL signal after the grace period expires' do
            expect(Gitlab::ProcessManagement).to receive(:trap_signals).with(%i[INT TERM]).and_yield(:TERM)
            expect(Gitlab::ProcessManagement).to receive(:signal_processes).ordered.with(process_ids, :TERM)
            expect(supervisor).to receive(:sleep).ordered.with(check_terminate_interval_seconds).at_least(:once)
            expect(Gitlab::ProcessManagement).to receive(:signal_processes).ordered.with(process_ids, '-KILL')

            supervisor.supervise(process_ids) { [] }
          end
        end
      end

      context 'forwarded signals' do
        let(:forwarded_signals) { %i[USR1] }

        it 'forwards given signals to the observed processes' do
          expect(Gitlab::ProcessManagement).to receive(:trap_signals).with(%i[USR1]).and_yield(:USR1)
          expect(Gitlab::ProcessManagement).to receive(:signal_processes).ordered.with(process_ids, :USR1)

          supervisor.supervise(process_ids) { [] }
        end
      end
    end
  end

  describe '#shutdown' do
    context 'when supervisor is supervising processes' do
      before do
        supervisor.supervise(process_ids)
      end

      context 'when supervisor is alive' do
        it 'signals TERM then KILL to all supervised processes' do
          expect(Gitlab::ProcessManagement).to receive(:signal_processes).ordered.with(process_ids, :TERM)
          expect(Gitlab::ProcessManagement).to receive(:signal_processes).ordered.with(process_ids, '-KILL')

          supervisor.shutdown
        end

        it 'stops the supervisor' do
          expect { supervisor.shutdown }.to change { supervisor.alive }.from(true).to(false)
        end
      end

      context 'when supervisor has already shut down' do
        before do
          supervisor.shutdown
        end

        it 'does nothing' do
          expect(supervisor.alive).to be(false)
          expect(Gitlab::ProcessManagement).not_to receive(:signal_processes)

          supervisor.shutdown
        end
      end
    end

    context 'when supervisor never started' do
      it 'does nothing' do
        expect(supervisor.alive).to be(false)
        expect(Gitlab::ProcessManagement).not_to receive(:signal_processes)

        supervisor.shutdown
      end
    end
  end

  def await_condition(timeout_sec: 5, sleep_sec: 0.1)
    Timeout.timeout(timeout_sec) do
      sleep sleep_sec until yield
    end
  end
end
