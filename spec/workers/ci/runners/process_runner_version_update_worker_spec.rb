# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Runners::ProcessRunnerVersionUpdateWorker, feature_category: :fleet_visibility do
  subject(:worker) { described_class.new }

  describe '#perform' do
    let(:version) { '1.0.0' }
    let(:job_args) { version }

    include_examples 'an idempotent worker' do
      subject(:perform_twice) { perform_multiple(job_args, worker: worker, exec_times: 2) }

      let(:service) { ::Ci::Runners::ProcessRunnerVersionUpdateService.new(version) }
      let(:available_runner_releases) do
        %w[1.0.0 1.0.1]
      end

      before do
        allow(Ci::Runners::ProcessRunnerVersionUpdateService).to receive(:new).and_return(service)
        allow(service).to receive(:execute).and_call_original

        url = ::Gitlab::CurrentSettings.current_application_settings.public_runner_releases_url

        WebMock.stub_request(:get, url).to_return(
          body: available_runner_releases.map { |v| { name: v } }.to_json,
          status: 200,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'logs the service result', :aggregate_failures do
        perform_twice

        expect(Ci::Runners::ProcessRunnerVersionUpdateService).to have_received(:new).twice
        expect(service).to have_received(:execute).twice
        expect(worker.logging_extras).to eq(
          {
            'extra.ci_runners_process_runner_version_update_worker.status' => :success,
            'extra.ci_runners_process_runner_version_update_worker.message' => nil,
            'extra.ci_runners_process_runner_version_update_worker.upgrade_status' => 'recommended'
          }
        )
      end
    end
  end
end
