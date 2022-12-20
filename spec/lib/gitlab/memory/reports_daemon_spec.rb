# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Memory::ReportsDaemon, :aggregate_failures do
  let(:reporter) { instance_double(Gitlab::Memory::Reporter) }
  let(:reports) { nil }

  subject(:daemon) { described_class.new(reporter: reporter, reports: reports) }

  describe '#run_thread' do
    before do
      # make sleep no-op
      allow(daemon).to receive(:sleep) {}

      # let alive return 3 times: true, true, false
      allow(daemon).to receive(:alive).and_return(true, true, false)
    end

    context 'with default reports' do
      it 'runs them using the given reporter' do
        expect(reporter).to receive(:run_report).twice.with(an_instance_of(Gitlab::Memory::Reports::JemallocStats))

        daemon.send(:run_thread)
      end
    end

    context 'with inactive reports' do
      # rubocop: disable RSpec/VerifiedDoubles
      # We test how ReportsDaemon could be extended in the future
      # We configure it with new reports classes which are not yet defined so we cannot make this an instance_double.
      let(:active_report_1) { double("Active Report 1", active?: true) }
      let(:active_report_2) { double("Active Report 2", active?: true) }
      let(:inactive_report) { double("Inactive Report", active?: false) }
      # rubocop: enable RSpec/VerifiedDoubles

      let(:reports) do
        [active_report_1, active_report_2, inactive_report]
      end

      it 'runs only active reports' do
        expect(reporter).to receive(:run_report).ordered.with(active_report_1)
        expect(reporter).to receive(:run_report).ordered.with(active_report_2)
        expect(reporter).to receive(:run_report).ordered.with(active_report_1)
        expect(reporter).to receive(:run_report).ordered.with(active_report_2)
        expect(reporter).not_to receive(:run_report).with(inactive_report)

        daemon.send(:run_thread)
      end
    end

    context 'sleep timers logic' do
      it 'wakes up every (fixed interval + defined delta), sleeps between reports each cycle' do
        stub_env('GITLAB_DIAGNOSTIC_REPORTS_SLEEP_MAX_DELTA_S', 1) # rand(1) == 0, so we will have fixed sleep interval
        daemon = described_class.new(reporter: reporter, reports: reports)
        allow(daemon).to receive(:alive).and_return(true, true, false)
        allow(reporter).to receive(:run_report)

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
      end
    end

    context 'when settings are passed through the environment' do
      before do
        stub_env('GITLAB_DIAGNOSTIC_REPORTS_SLEEP_S', 100)
        stub_env('GITLAB_DIAGNOSTIC_REPORTS_SLEEP_MAX_DELTA_S', 50)
        stub_env('GITLAB_DIAGNOSTIC_REPORTS_SLEEP_BETWEEN_REPORTS_S', 2)
      end

      it 'uses provided values' do
        daemon = described_class.new

        expect(daemon.sleep_s).to eq(100)
        expect(daemon.sleep_max_delta_s).to eq(50)
        expect(daemon.sleep_between_reports_s).to eq(2)
      end
    end
  end
end
