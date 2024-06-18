# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::PauseControl::Client, :clean_gitlab_redis_queues, feature_category: :global_search do
  let(:worker_class) do
    Class.new do
      def self.name
        'TestPauseWorker'
      end

      include ApplicationWorker

      pause_control :zoekt

      def perform(*); end
    end
  end

  before do
    stub_const('TestPauseWorker', worker_class)
  end

  describe '#call' do
    context 'when strategy is enabled' do
      before do
        allow(Gitlab::CurrentSettings).to receive(:zoekt_indexing_paused?).and_return(true)
      end

      it 'does not schedule the job' do
        expect(Gitlab::SidekiqMiddleware::PauseControl::PauseControlService).to receive(:add_to_waiting_queue!).once

        TestPauseWorker.perform_async('args1')

        expect(TestPauseWorker.jobs.count).to eq(0)
      end
    end

    context 'when strategy is disabled' do
      before do
        allow(Gitlab::CurrentSettings).to receive(:zoekt_indexing_paused?).and_return(false)
      end

      it 'schedules the job' do
        expect(Gitlab::SidekiqMiddleware::PauseControl::PauseControlService).not_to receive(:add_to_waiting_queue!)

        TestPauseWorker.perform_async('args1')

        expect(TestPauseWorker.jobs.count).to eq(1)
      end
    end
  end
end
