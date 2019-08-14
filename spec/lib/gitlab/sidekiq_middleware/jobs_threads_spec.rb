require 'spec_helper'

describe Gitlab::SidekiqMiddleware::JobsThreads do
  subject { described_class.new }

  let(:worker) { double(:worker, class: Chaos::SleepWorker) }
  let(:jid) { '581f90fbd2f24deabcbde2f9' }
  let(:job) { { 'jid' => jid } }
  let(:jid_thread) { '684f90fbd2f24deabcbde2f9' }
  let(:job_thread) { { 'jid' => jid_thread } }
  let(:queue) { 'test_queue' }
  let(:mark_job_as_cancelled) { Sidekiq.redis {|c| c.setex("cancelled-#{jid}", 2, 1) } }

  def run_job
    subject.call(worker, job, queue) do
      sleep 2
      "mock return from yield"
    end
  end

  def run_job_thread
    Thread.new do
      subject.call(worker, job_thread, queue) do
        sleep 3
        "mock return from yield"
      end
    end
  end

  describe '.call' do
    context 'by default' do
      it 'return from yield' do
        expect(run_job).to eq("mock return from yield")
      end
    end

    context 'when job is marked as cancelled' do
      before do
        mark_job_as_cancelled
      end

      it 'return directly' do
        expect(run_job).to be_nil
      end
    end
  end

  describe '.self.interrupt' do
    before do
      run_job_thread
      sleep 1
    end

    it 'interrupt the job with correct jid' do
      expect(described_class.jobs[jid_thread]).to receive(:raise).with(Interrupt)
      expect(described_class.interrupt jid_thread).to eq(described_class.jobs[jid_thread])
    end

    it 'do nothing with wrong jid' do
      expect(described_class.jobs[jid_thread]).not_to receive(:raise)
      expect(described_class.interrupt 'wrong_jid').to be_nil
    end
  end

  describe '.self.cancelled?' do
    it 'return true when job is marked as cancelled' do
      mark_job_as_cancelled
      expect(described_class.cancelled? jid).to be true
    end

    it 'return false when job is not marked as cancelled' do
      expect(described_class.cancelled? 'non-exists-jid').to be false
    end
  end

  describe '.self.mark_job_as_cancelled' do
    it 'set Redis key' do
      described_class.mark_job_as_cancelled('jid_123')

      expect(described_class.cancelled? 'jid_123').to be true
    end
  end
end
