require 'spec_helper'

describe Gitlab::SidekiqVersioning::Middleware do
  subject { described_class.new }

  let(:worker_class) do
    Class.new do
      def self.name
        'DummyWorker'
      end

      include ApplicationWorker

      version 2
    end
  end

  describe '#call' do
    let(:worker) { worker_class.new }
    let(:job) { { 'version' => 3, 'queue' => queue } }
    let(:queue) { worker_class.queue }

    def call!(&block)
      block ||= -> {}
      subject.call(worker, job, queue, &block)
    end

    context 'when the job is unsupported' do
      before do
        allow(Gitlab::SidekiqVersioning).to receive(:requeue_unsupported_job).and_return(true)
      end

      it 'sets worker.job_version' do
        call!

        expect(worker.job_version).to eq(job['version'])
      end

      it 'sets job[do_not_unset_sidekiq_status]' do
        call!

        expect(job['do_not_unset_sidekiq_status']).to be_truthy
      end

      it 'does not yield' do
        expect { |b| call!(&b) }.not_to yield_control
      end
    end

    context 'when the job is supported' do
      before do
        allow(Gitlab::SidekiqVersioning).to receive(:requeue_unsupported_job).and_return(false)
      end

      it 'sets worker.job_version' do
        call!

        expect(worker.job_version).to eq(job['version'])
      end

      it 'yields' do
        expect { |b| call!(&b) }.to yield_control
      end
    end
  end
end
