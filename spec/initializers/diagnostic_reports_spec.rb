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

    context 'when run in application context' do
      before do
        allow(::Gitlab::Runtime).to receive(:application?).and_return(true)
      end

      it 'modifies worker startup hooks' do
        report_daemon = instance_double(Gitlab::Memory::ReportsDaemon)

        expect(Gitlab::Cluster::LifecycleEvents).to receive(:on_worker_start).and_call_original
        expect(Gitlab::Memory::ReportsDaemon).to receive(:instance).and_return(report_daemon)
        expect(report_daemon).to receive(:start)

        load_initializer
      end
    end

    context 'when run in non-application context, such as rails console or tests' do
      before do
        allow(::Gitlab::Runtime).to receive(:application?).and_return(false)
      end

      include_examples 'does not modify worker startup hooks'
    end
  end

  context 'when GITLAB_DIAGNOSTIC_REPORTS_ENABLED is not set' do
    before do
      allow(::Gitlab::Runtime).to receive(:application?).and_return(true)
    end

    include_examples 'does not modify worker startup hooks'
  end

  context 'when GITLAB_DIAGNOSTIC_REPORTS_ENABLED is set to false' do
    before do
      stub_env('GITLAB_DIAGNOSTIC_REPORTS_ENABLED', false)
      allow(::Gitlab::Runtime).to receive(:application?).and_return(true)
    end

    include_examples 'does not modify worker startup hooks'
  end
end
