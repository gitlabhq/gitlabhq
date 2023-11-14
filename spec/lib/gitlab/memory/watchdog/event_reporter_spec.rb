# frozen_string_literal: true

require 'fast_spec_helper'
require 'prometheus/client'

RSpec.describe Gitlab::Memory::Watchdog::EventReporter, feature_category: :cloud_connector do
  let(:logger) { instance_double(::Logger) }
  let(:violations_counter) { instance_double(::Prometheus::Client::Counter) }
  let(:violations_handled_counter) { instance_double(::Prometheus::Client::Counter) }
  let(:reporter) { described_class.new(logger: logger) }

  def stub_prometheus_metrics
    allow(Gitlab::Metrics).to receive(:counter)
                                .with(:gitlab_memwd_violations_total, anything, anything)
                                .and_return(violations_counter)
    allow(Gitlab::Metrics).to receive(:counter)
                                .with(:gitlab_memwd_violations_handled_total, anything, anything)
                                .and_return(violations_handled_counter)

    allow(violations_counter).to receive(:increment)
    allow(violations_handled_counter).to receive(:increment)
  end

  before do
    stub_prometheus_metrics
    allow(Gitlab::Metrics::System).to receive(:memory_usage_rss).at_least(:once).and_return(
      total: 1024
    )
    allow(::Prometheus::PidProvider).to receive(:worker_id).and_return('worker_1')
  end

  describe '#logger' do
    context 'when logger is not provided' do
      let(:reporter) { described_class.new }

      it 'uses default Gitlab::AppLogger' do
        expect(reporter.logger).to eq(Gitlab::AppLogger)
      end
    end
  end

  describe '#started' do
    it 'logs start message once' do
      expect(logger).to receive(:info).once
        .with(
          pid: Process.pid,
          worker_id: 'worker_1',
          custom_label: 'dummy_label',
          memwd_rss_bytes: 1024,
          message: 'started')

      reporter.started(custom_label: 'dummy_label')
    end
  end

  describe '#stopped' do
    subject { reporter.stopped(custom_label: 'dummy_label') }

    it 'logs stop message once' do
      expect(logger).to receive(:info).once
        .with(
          pid: Process.pid,
          worker_id: 'worker_1',
          custom_label: 'dummy_label',
          memwd_rss_bytes: 1024,
          message: 'stopped')

      reporter.stopped(custom_label: 'dummy_label')
    end
  end

  describe '#threshold_violated' do
    subject { reporter.threshold_violated(:monitor_name) }

    it 'increments violations counter' do
      expect(violations_counter).to receive(:increment).with(reason: :monitor_name)

      subject
    end

    it 'does not increment handled violations counter' do
      expect(violations_handled_counter).not_to receive(:increment)

      subject
    end

    it 'does not log violation' do
      expect(logger).not_to receive(:warn)

      subject
    end
  end

  describe '#strikes_exceeded' do
    subject { reporter.strikes_exceeded(:monitor_name, { message: 'dummy_text' }) }

    before do
      allow(logger).to receive(:warn)
    end

    it 'increments handled violations counter' do
      expect(violations_handled_counter).to receive(:increment).with(reason: :monitor_name)

      subject
    end

    it 'logs violation' do
      expect(logger).to receive(:warn)
        .with({
          pid: Process.pid,
          worker_id: 'worker_1',
          memwd_rss_bytes: 1024,
          message: 'dummy_text'
        })

      subject
    end
  end
end
