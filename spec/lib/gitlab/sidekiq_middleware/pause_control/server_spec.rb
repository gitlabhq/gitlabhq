# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::PauseControl::Server, :clean_gitlab_redis_queues, feature_category: :global_search do
  let(:worker_class) do
    Class.new do
      def self.name
        'TestPauseWorker'
      end

      include ApplicationWorker

      pause_control :zoekt

      def perform(*)
        self.class.work
      end

      def self.work; end
    end
  end

  before do
    stub_const('TestPauseWorker', worker_class)
  end

  around do |example|
    with_sidekiq_server_middleware do |chain|
      chain.add described_class
      Sidekiq::Testing.inline! { example.run }
    end
  end

  describe '#call' do
    context 'when strategy is enabled' do
      before do
        allow(Gitlab::CurrentSettings).to receive(:zoekt_indexing_paused?).and_return(true)
      end

      it 'puts the job to another queue without execution' do
        bare_job = { 'class' => 'TestPauseWorker', 'args' => ['hello'] }
        job_definition = Gitlab::SidekiqMiddleware::PauseControl::StrategyHandler.new(TestPauseWorker, bare_job.dup)

        expect(Gitlab::SidekiqMiddleware::PauseControl::StrategyHandler)
          .to receive(:new).with(TestPauseWorker, a_hash_including(bare_job))
                .and_return(job_definition).once

        expect(TestPauseWorker).not_to receive(:work)
        expect(Gitlab::SidekiqMiddleware::PauseControl::PauseControlService).to receive(:add_to_waiting_queue!).once

        TestPauseWorker.perform_async('hello')
      end
    end

    context 'when strategy is disabled' do
      before do
        allow(Gitlab::CurrentSettings).to receive(:zoekt_indexing_paused?).and_return(false)
      end

      it 'executes the job' do
        bare_job = { 'class' => 'TestPauseWorker', 'args' => ['hello'] }
        job_definition = Gitlab::SidekiqMiddleware::PauseControl::StrategyHandler.new(TestPauseWorker, bare_job.dup)

        expect(Gitlab::SidekiqMiddleware::PauseControl::StrategyHandler)
          .to receive(:new).with(TestPauseWorker, hash_including(bare_job))
                .and_return(job_definition).twice

        expect(TestPauseWorker).to receive(:work)
        expect(Gitlab::SidekiqMiddleware::PauseControl::PauseControlService).not_to receive(:add_to_waiting_queue!)

        TestPauseWorker.perform_async('hello')
      end
    end
  end
end
