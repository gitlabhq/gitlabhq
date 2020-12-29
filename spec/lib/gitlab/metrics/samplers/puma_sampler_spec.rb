# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Samplers::PumaSampler do
  subject { described_class.new }

  let(:null_metric) { double('null_metric', set: nil, observe: nil) }

  before do
    allow(Gitlab::Metrics::NullMetric).to receive(:instance).and_return(null_metric)
  end

  it_behaves_like 'metrics sampler', 'PUMA_SAMPLER'

  describe '#sample' do
    before do
      expect(subject).to receive(:puma_stats).and_return(puma_stats)
    end

    context 'in cluster mode' do
      let(:puma_stats) do
        <<~EOS
        {
          "workers": 2,
          "phase": 2,
          "booted_workers": 2,
          "old_workers": 0,
          "worker_status": [{
            "pid": 32534,
            "index": 0,
            "phase": 1,
            "booted": true,
            "last_checkin": "2019-05-15T07:57:55Z",
            "last_status": {
              "backlog":0,
              "running":1,
              "pool_capacity":4,
              "max_threads": 4
            }
          }]
        }
        EOS
      end

      it 'samples master statistics' do
        labels = { worker: 'master' }

        expect(subject.metrics[:puma_workers]).to receive(:set).with(labels, 2)
        expect(subject.metrics[:puma_running_workers]).to receive(:set).with(labels, 2)
        expect(subject.metrics[:puma_stale_workers]).to receive(:set).with(labels, 0)

        subject.sample
      end

      it 'samples worker statistics' do
        labels = { worker: 'worker_0' }

        expect_worker_stats(labels)

        subject.sample
      end
    end

    context 'with empty worker stats' do
      let(:puma_stats) do
        <<~EOS
        {
          "workers": 2,
          "phase": 2,
          "booted_workers": 2,
          "old_workers": 0,
          "worker_status": [{
            "pid": 32534,
            "index": 0,
            "phase": 1,
            "booted": true,
            "last_checkin": "2019-05-15T07:57:55Z",
            "last_status": {}
          }]
        }
        EOS
      end

      it 'does not log worker stats' do
        expect(subject).not_to receive(:set_worker_metrics)

        subject.sample
      end
    end

    context 'in single mode' do
      let(:puma_stats) do
        <<~EOS
        {
          "backlog":0,
          "running":1,
          "pool_capacity":4,
          "max_threads": 4
        }
        EOS
      end

      it 'samples worker statistics' do
        labels = {}

        expect(subject.metrics[:puma_workers]).to receive(:set).with(labels, 1)
        expect(subject.metrics[:puma_running_workers]).to receive(:set).with(labels, 1)
        expect_worker_stats(labels)

        subject.sample
      end
    end
  end

  def expect_worker_stats(labels)
    expect(subject.metrics[:puma_queued_connections]).to receive(:set).with(labels, 0)
    expect(subject.metrics[:puma_active_connections]).to receive(:set).with(labels, 0)
    expect(subject.metrics[:puma_running]).to receive(:set).with(labels, 1)
    expect(subject.metrics[:puma_pool_capacity]).to receive(:set).with(labels, 4)
    expect(subject.metrics[:puma_max_threads]).to receive(:set).with(labels, 4)
    expect(subject.metrics[:puma_idle_threads]).to receive(:set).with(labels, 1)
  end
end
