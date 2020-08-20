# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqVersioning::Middleware do
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

    it 'sets worker.job_version' do
      call!

      expect(worker.job_version).to eq(job['version'])
    end

    it 'yields' do
      expect { |b| call!(&b) }.to yield_control
    end

    context 'when worker is not ApplicationWorker' do
      let(:worker_class) do
        ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper
      end

      it 'does not err' do
        expect { call! }.not_to raise_error
      end
    end
  end
end
