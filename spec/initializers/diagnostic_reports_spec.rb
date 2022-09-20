# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'diagnostic reports' do
  subject(:load_initializer) do
    load Rails.root.join('config/initializers/diagnostic_reports.rb')
  end

  shared_examples 'does not modify worker startup hooks' do
    it do
      expect(Gitlab::Cluster::LifecycleEvents).not_to receive(:on_worker_start)
      expect(Gitlab::Memory::ReportsDaemon).not_to receive(:instance)

      load_initializer
    end
  end

  context 'when GITLAB_DIAGNOSTIC_REPORTS_ENABLED is set to true' do
    before do
      stub_env('GITLAB_DIAGNOSTIC_REPORTS_ENABLED', true)
    end

    context 'when run in Puma context' do
      before do
        allow(::Gitlab::Runtime).to receive(:puma?).and_return(true)
      end

      let(:report_daemon) { instance_double(Gitlab::Memory::ReportsDaemon) }

      it 'modifies worker startup hooks, starts Gitlab::Memory::ReportsDaemon' do
        expect(Gitlab::Cluster::LifecycleEvents).to receive(:on_worker_start).and_call_original

        expect_next_instance_of(Gitlab::Memory::ReportsDaemon) do |daemon|
          expect(daemon).to receive(:start).and_call_original

          # make sleep no-op
          allow(daemon).to receive(:sleep).and_return(nil)

          # let alive return 3 times: true, true, false
          allow(daemon).to receive(:alive).and_return(true, true, false)
        end

        load_initializer
      end

      context 'with `Gitlab::Memory::UploadAndCleanupReports` added into initializer' do
        before do
          allow(Gitlab::Memory::ReportsDaemon).to receive(:instance).and_return(report_daemon)
          allow(report_daemon).to receive(:start)
        end

        context 'when run from `puma_0` worker process' do
          let(:uploader) { instance_double(Gitlab::Memory::UploadAndCleanupReports) }
          let(:background_task) { instance_double(Gitlab::BackgroundTask) }

          before do
            allow(Prometheus::PidProvider).to receive(:worker_id).and_return('puma_0')
          end

          it 'sets up `Gitlab::Memory::UploadAndCleanupReports` as `BackgroundTask`' do
            expect(Gitlab::Memory::UploadAndCleanupReports).to receive(:new).and_return(uploader)
            expect(Gitlab::BackgroundTask).to receive(:new).with(uploader).and_return(background_task)
            expect(background_task).to receive(:start)

            load_initializer
          end
        end

        context 'when run from worker process other than `puma_0`' do
          before do
            allow(Prometheus::PidProvider).to receive(:worker_id).and_return('puma_1')
          end

          it 'does not set up `Gitlab::Memory::UploadAndCleanupReports`' do
            expect(Gitlab::Memory::UploadAndCleanupReports).not_to receive(:new)
            expect(Gitlab::BackgroundTask).not_to receive(:new)

            load_initializer
          end
        end
      end
    end

    context 'when run in non-Puma context, such as rails console, tests, Sidekiq' do
      before do
        allow(::Gitlab::Runtime).to receive(:puma?).and_return(false)
      end

      include_examples 'does not modify worker startup hooks'
    end
  end

  context 'when GITLAB_DIAGNOSTIC_REPORTS_ENABLED is not set' do
    before do
      allow(::Gitlab::Runtime).to receive(:puma?).and_return(true)
    end

    include_examples 'does not modify worker startup hooks'
  end

  context 'when GITLAB_DIAGNOSTIC_REPORTS_ENABLED is set to false' do
    before do
      stub_env('GITLAB_DIAGNOSTIC_REPORTS_ENABLED', false)
      allow(::Gitlab::Runtime).to receive(:puma?).and_return(true)
    end

    include_examples 'does not modify worker startup hooks'
  end
end
