require 'spec_helper'

describe Gitlab::SidekiqMiddleware::Shutdown do
  subject { described_class.new }

  let(:pid) { Process.pid }
  let(:worker) { double(:worker, class: 'TestWorker') }
  let(:job) { { 'jid' => 123 } }
  let(:queue) { 'test_queue' }
  let(:block) { proc { nil } }

  def run
    subject.call(worker, job, queue) { block.call }
    described_class.shutdown_thread&.join
  end

  def pop_trace
    subject.trace.pop(true)
  end

  before do
    allow(subject).to receive(:get_rss).and_return(10.kilobytes)
    described_class.clear_shutdown_thread
  end

  context 'when MAX_RSS is set to 0' do
    before do
      stub_const("#{described_class}::MAX_RSS", 0)
    end

    it 'does nothing' do
      expect(subject).not_to receive(:sleep)

      run
    end
  end

  def expect_shutdown_sequence
    expect(pop_trace).to eq([:sleep, 15 * 60])
    expect(pop_trace).to eq([:kill, 'SIGTSTP', pid])

    expect(pop_trace).to eq([:sleep, 30])
    expect(pop_trace).to eq([:kill, 'SIGTERM', pid])

    expect(pop_trace).to eq([:sleep, 10])
    expect(pop_trace).to eq([:kill, 'SIGKILL', pid])
  end

  context 'when MAX_RSS is exceeded' do
    before do
      stub_const("#{described_class}::MAX_RSS", 5.kilobytes)
    end

    it 'sends the TSTP, TERM and KILL signals at expected times' do
      run

      expect_shutdown_sequence
    end
  end

  context 'when MAX_RSS is not exceeded' do
    before do
      stub_const("#{described_class}::MAX_RSS", 15.kilobytes)
    end

    it 'does nothing' do
      expect(subject).not_to receive(:sleep)

      run
    end
  end

  context 'when WantShutdown is raised' do
    let(:block) { proc { raise described_class::WantShutdown } }

    it 'starts the shutdown sequence and re-raises the exception' do
      expect { run }.to raise_exception(described_class::WantShutdown)

      # We can't expect 'run' to have joined on the shutdown thread, because
      # it hit an exception.
      shutdown_thread = described_class.shutdown_thread
      expect(shutdown_thread).not_to be_nil
      shutdown_thread.join

      expect_shutdown_sequence
    end
  end
end
