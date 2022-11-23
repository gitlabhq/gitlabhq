# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Memory::Reporter, :aggregate_failures do
  subject(:reporter) { described_class.new }

  let(:fake_report) do
    Class.new do
      attr_reader :did_run

      def name
        'fake_report'
      end

      def run(report_id)
        @did_run = true
        '/path/to/report'
      end
    end
  end

  let(:report) { fake_report.new }

  describe '#run_report' do
    let(:report_duration_counter) { instance_double(::Prometheus::Client::Counter) }
    let(:file_size) { 1_000_000 }

    before do
      allow(Gitlab::Metrics).to receive(:counter).and_return(report_duration_counter)
      allow(report_duration_counter).to receive(:increment)

      allow(::Prometheus::PidProvider).to receive(:worker_id).and_return('worker_1')
      allow(File).to receive(:size).with('/path/to/report').and_return(file_size)

      allow(SecureRandom).to receive(:uuid).and_return('abc123')
    end

    it 'runs the given report' do
      expect { reporter.run_report(report) }.to change { report.did_run }.from(nil).to(true)
    end

    it 'logs duration and other metrics' do
      expect(Gitlab::AppLogger).to receive(:info).with(
        hash_including(
          :duration_s,
          :cpu_s,
          perf_report_size_bytes: file_size,
          message: 'finished',
          pid: Process.pid,
          worker_id: 'worker_1',
          perf_report_worker_uuid: 'abc123',
          perf_report: 'fake_report'
        ))

      reporter.run_report(report)
    end

    it 'increments Prometheus duration counter' do
      expect(report_duration_counter).to receive(:increment).with({ report: 'fake_report' }, an_instance_of(Float))

      reporter.run_report(report)
    end

    context 'when the report returns invalid file path' do
      before do
        allow(File).to receive(:size).with('/path/to/report').and_raise(Errno::ENOENT)
      end

      it 'logs `0` as `perf_report_size_bytes`' do
        expect(Gitlab::AppLogger).to receive(:info).with(hash_including(perf_report_size_bytes: 0))

        reporter.run_report(report)
      end
    end
  end
end
