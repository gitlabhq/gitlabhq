# frozen_string_literal: true

require_relative '../../../lib/gitlab/process_supervisor'

RSpec.describe Gitlab::ProcessSupervisor do
  let(:health_check_interval_seconds) { 0.1 }
  let(:check_terminate_interval_seconds) { 1 }
  let(:forwarded_signals) { [] }
  let(:process_id) do
    Process.spawn('while true; do sleep 1; done').tap do |pid|
      Process.detach(pid)
    end
  end

  subject(:supervisor) do
    described_class.new(
      health_check_interval_seconds: health_check_interval_seconds,
      check_terminate_interval_seconds: check_terminate_interval_seconds,
      terminate_timeout_seconds: 1 + check_terminate_interval_seconds,
      forwarded_signals: forwarded_signals
    )
  end

  after do
    if Gitlab::ProcessManagement.process_alive?(process_id)
      Process.kill('KILL', process_id)
    end
  end

  describe '#supervise' do
    context 'while supervised process is alive' do
      it 'does not invoke callback' do
        expect(Gitlab::ProcessManagement.process_alive?(process_id)).to be(true)
        pids_killed = []

        thread = Thread.new do
          supervisor.supervise(process_id) do |dead_pids|
            pids_killed = dead_pids
            []
          end
        end

        # Wait several times the poll frequency of the supervisor.
        sleep health_check_interval_seconds * 10
        thread.terminate

        expect(pids_killed).to be_empty
        expect(Gitlab::ProcessManagement.process_alive?(process_id)).to be(true)
      end
    end

    context 'when supervised process dies' do
      it 'triggers callback with the dead PIDs' do
        expect(Gitlab::ProcessManagement.process_alive?(process_id)).to be(true)
        pids_killed = []

        thread = Thread.new do
          supervisor.supervise(process_id) do |dead_pids|
            pids_killed = dead_pids
            []
          end
        end

        # Terminate the supervised process.
        Process.kill('TERM', process_id)

        await_condition(sleep_sec: health_check_interval_seconds) do
          pids_killed == [process_id]
        end
        thread.terminate

        expect(Gitlab::ProcessManagement.process_alive?(process_id)).to be(false)
      end
    end

    context 'signal handling' do
      before do
        allow(supervisor).to receive(:sleep)
        allow(Gitlab::ProcessManagement).to receive(:trap_signals)
        allow(Gitlab::ProcessManagement).to receive(:all_alive?).and_return(false)
        allow(Gitlab::ProcessManagement).to receive(:signal_processes).with([process_id], anything)
      end

      context 'termination signals' do
        context 'when TERM results in timely shutdown of processes' do
          it 'forwards them to observed processes without waiting for grace period to expire' do
            allow(Gitlab::ProcessManagement).to receive(:any_alive?).and_return(false)

            expect(Gitlab::ProcessManagement).to receive(:trap_signals).ordered.with(%i(INT TERM)).and_yield(:TERM)
            expect(Gitlab::ProcessManagement).to receive(:signal_processes).ordered.with([process_id], :TERM)
            expect(supervisor).not_to receive(:sleep).with(check_terminate_interval_seconds)

            supervisor.supervise(process_id) { [] }
          end
        end

        context 'when TERM does not result in timely shutdown of processes' do
          it 'issues a KILL signal after the grace period expires' do
            expect(Gitlab::ProcessManagement).to receive(:trap_signals).with(%i(INT TERM)).and_yield(:TERM)
            expect(Gitlab::ProcessManagement).to receive(:signal_processes).ordered.with([process_id], :TERM)
            expect(supervisor).to receive(:sleep).ordered.with(check_terminate_interval_seconds).at_least(:once)
            expect(Gitlab::ProcessManagement).to receive(:signal_processes).ordered.with([process_id], '-KILL')

            supervisor.supervise(process_id) { [] }
          end
        end
      end

      context 'forwarded signals' do
        let(:forwarded_signals) { %i(USR1) }

        it 'forwards given signals to the observed processes' do
          expect(Gitlab::ProcessManagement).to receive(:trap_signals).with(%i(USR1)).and_yield(:USR1)
          expect(Gitlab::ProcessManagement).to receive(:signal_processes).ordered.with([process_id], :USR1)

          supervisor.supervise(process_id) { [] }
        end
      end
    end
  end

  def await_condition(timeout_sec: 5, sleep_sec: 0.1)
    Timeout.timeout(timeout_sec) do
      sleep sleep_sec until yield
    end
  end
end
