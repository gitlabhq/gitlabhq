# frozen_string_literal: true

require 'fast_spec_helper'
require 'puma_worker_killer'

RSpec.describe Gitlab::Cluster::PumaWorkerKillerInitializer do
  describe '.start' do
    context 'when GITLAB_MEMORY_WATCHDOG_ENABLED is false' do
      before do
        stub_env('GITLAB_MEMORY_WATCHDOG_ENABLED', 'false')
      end

      it 'configures and start PumaWorkerKiller' do
        expect(PumaWorkerKiller).to receive(:config)
        expect(PumaWorkerKiller).to receive(:start)

        described_class.start({})
      end
    end

    context 'when GITLAB_MEMORY_WATCHDOG_ENABLED is not set' do
      it 'configures and start PumaWorkerKiller' do
        expect(PumaWorkerKiller).not_to receive(:config)
        expect(PumaWorkerKiller).not_to receive(:start)

        described_class.start({})
      end
    end
  end
end
