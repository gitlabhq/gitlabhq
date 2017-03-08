require 'spec_helper'

describe Gitlab::SidekiqCluster::CLI do
  let(:cli) { described_class.new('/dev/null') }

  describe '#run' do
    context 'without any arguments' do
      it 'raises CommandError' do
        expect { cli.run([]) }.to raise_error(described_class::CommandError)
      end
    end

    context 'with arguments' do
      it 'starts the Sidekiq workers' do
        expect(Gitlab::SidekiqCluster).to receive(:start).and_return([])
        expect(cli).to receive(:write_pid)
        expect(cli).to receive(:trap_signals)
        expect(cli).to receive(:start_loop)

        cli.run(%w(foo))
      end
    end
  end

  describe '#write_pid' do
    context 'when a PID is specified' do
      it 'writes the PID to a file' do
        expect(Gitlab::SidekiqCluster).to receive(:write_pid).with('/dev/null')

        cli.option_parser.parse!(%w(-P /dev/null))
        cli.write_pid
      end
    end

    context 'when no PID is specified' do
      it 'does not write a PID' do
        expect(Gitlab::SidekiqCluster).not_to receive(:write_pid)

        cli.write_pid
      end
    end
  end

  describe '#trap_signals' do
    it 'traps the termination and forwarding signals' do
      expect(Gitlab::SidekiqCluster).to receive(:trap_terminate)
      expect(Gitlab::SidekiqCluster).to receive(:trap_forward)

      cli.trap_signals
    end
  end

  describe '#start_loop' do
    it 'runs until one of the processes has been terminated' do
      allow(cli).to receive(:sleep).with(a_kind_of(Numeric))

      expect(Gitlab::SidekiqCluster).to receive(:all_alive?)
        .with(an_instance_of(Array)).and_return(false)

      expect(Gitlab::SidekiqCluster).to receive(:signal_processes)
        .with(an_instance_of(Array), :TERM)

      cli.start_loop
    end
  end
end
