# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Memory::ReportsDaemon do
  let(:daemon) { described_class.new }

  describe '#run_thread' do
    let(:report_duration_counter) { instance_double(::Prometheus::Client::Counter) }
    let(:file_size) { 1_000_000 }

    before do
      allow(Gitlab::Metrics).to receive(:counter).and_return(report_duration_counter)
      allow(report_duration_counter).to receive(:increment)

      # make sleep no-op
      allow(daemon).to receive(:sleep) {}

      # let alive return 3 times: true, true, false
      allow(daemon).to receive(:alive).and_return(true, true, false)

      allow(File).to receive(:size).with(/#{daemon.reports_path}.*\.json/).and_return(file_size)
    end

    it 'runs reports' do
      expect(daemon.send(:reports)).to all(receive(:run).twice.and_call_original)

      daemon.send(:run_thread)
    end

    it 'logs report execution' do
      expect(::Prometheus::PidProvider).to receive(:worker_id).at_least(:once).and_return('worker_1')

      expect(Gitlab::AppLogger).to receive(:info).with(
        hash_including(
          :duration_s,
          :cpu_s,
          perf_report_size_bytes: file_size,
          message: 'finished',
          pid: Process.pid,
          worker_id: 'worker_1',
          perf_report: 'jemalloc_stats'
        )).twice

      daemon.send(:run_thread)
    end

    context 'when the report object returns invalid file path' do
      before do
        allow(File).to receive(:size).with(/#{daemon.reports_path}.*\.json/).and_raise(Errno::ENOENT)
      end

      it 'logs `0` as `perf_report_size_bytes`' do
        expect(Gitlab::AppLogger).to receive(:info).with(hash_including(perf_report_size_bytes: 0)).twice

        daemon.send(:run_thread)
      end
    end

    it 'sets real time duration gauge' do
      expect(report_duration_counter).to receive(:increment).with({ report: 'jemalloc_stats' }, an_instance_of(Float))

      daemon.send(:run_thread)
    end

    it 'allows configure and run multiple reports' do
      # rubocop: disable RSpec/VerifiedDoubles
      # We test how ReportsDaemon could be extended in the future
      # We configure it with new reports classes which are not yet defined so we cannot make this an instance_double.
      active_report_1 = double("Active Report 1", active?: true)
      active_report_2 = double("Active Report 2", active?: true)
      inactive_report = double("Inactive Report", active?: false)
      # rubocop: enable RSpec/VerifiedDoubles

      allow(daemon).to receive(:reports).and_return([active_report_1, inactive_report, active_report_2])

      expect(active_report_1).to receive(:run).and_return('/tmp/report_1.json').twice
      expect(active_report_2).to receive(:run).and_return('/tmp/report_2.json').twice
      expect(inactive_report).not_to receive(:run)

      daemon.send(:run_thread)
    end

    context 'sleep timers logic' do
      it 'wakes up every (fixed interval + defined delta), sleeps between reports each cycle' do
        stub_env('GITLAB_DIAGNOSTIC_REPORTS_SLEEP_MAX_DELTA_S', 1) # rand(1) == 0, so we will have fixed sleep interval
        daemon = described_class.new
        allow(daemon).to receive(:alive).and_return(true, true, false)

        expect(daemon).to receive(:sleep).with(described_class::DEFAULT_SLEEP_S).ordered
        expect(daemon).to receive(:sleep).with(described_class::DEFAULT_SLEEP_BETWEEN_REPORTS_S).ordered
        expect(daemon).to receive(:sleep).with(described_class::DEFAULT_SLEEP_S).ordered
        expect(daemon).to receive(:sleep).with(described_class::DEFAULT_SLEEP_BETWEEN_REPORTS_S).ordered

        daemon.send(:run_thread)
      end
    end
  end

  describe '#stop_working' do
    it 'changes :alive to false' do
      expect { daemon.send(:stop_working) }.to change { daemon.send(:alive) }.from(true).to(false)
    end
  end

  context 'timer intervals settings' do
    context 'when no settings are set in the environment' do
      it 'uses defaults' do
        daemon = described_class.new

        expect(daemon.sleep_s).to eq(described_class::DEFAULT_SLEEP_S)
        expect(daemon.sleep_max_delta_s).to eq(described_class::DEFAULT_SLEEP_MAX_DELTA_S)
        expect(daemon.sleep_between_reports_s).to eq(described_class::DEFAULT_SLEEP_BETWEEN_REPORTS_S)
        expect(daemon.reports_path).to eq(described_class::DEFAULT_REPORTS_PATH)
      end
    end

    context 'when settings are passed through the environment' do
      before do
        stub_env('GITLAB_DIAGNOSTIC_REPORTS_SLEEP_S', 100)
        stub_env('GITLAB_DIAGNOSTIC_REPORTS_SLEEP_MAX_DELTA_S', 50)
        stub_env('GITLAB_DIAGNOSTIC_REPORTS_SLEEP_BETWEEN_REPORTS_S', 2)
        stub_env('GITLAB_DIAGNOSTIC_REPORTS_PATH', '/empty-dir')
      end

      it 'uses provided values' do
        daemon = described_class.new

        expect(daemon.sleep_s).to eq(100)
        expect(daemon.sleep_max_delta_s).to eq(50)
        expect(daemon.sleep_between_reports_s).to eq(2)
        expect(daemon.reports_path).to eq('/empty-dir')
      end
    end
  end
end
