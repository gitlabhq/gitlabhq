# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SidekiqMiddleware::Monitor do
  let(:monitor) { described_class.new }

  describe '#call' do
    let(:worker) { double }
    let(:job) { { 'jid' => 'job-id' } }
    let(:queue) { 'my-queue' }

    it 'calls SidekiqMonitor' do
      expect(Gitlab::SidekiqMonitor.instance).to receive(:within_job)
        .with('job-id', 'my-queue')
        .and_call_original

      expect { |blk| monitor.call(worker, job, queue, &blk) }.to yield_control
    end

    it 'passthroughs the return value' do
      result = monitor.call(worker, job, queue) do
        'value'
      end

      expect(result).to eq('value')
    end
  end
end
