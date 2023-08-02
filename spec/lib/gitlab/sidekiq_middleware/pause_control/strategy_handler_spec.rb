# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::PauseControl::StrategyHandler, :clean_gitlab_redis_queues, feature_category: :global_search do
  subject(:pause_control) do
    described_class.new(TestPauseWorker, job)
  end

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

  let(:job) { { 'class' => 'TestPauseWorker', 'args' => [1], 'jid' => '123' } }

  before do
    stub_const('TestPauseWorker', worker_class)
  end

  describe '#schedule' do
    shared_examples 'scheduling with pause control class' do |strategy_class|
      it 'calls schedule on the strategy' do
        expect do |block|
          klass = "Gitlab::SidekiqMiddleware::PauseControl::Strategies::#{strategy_class}".constantize
          expect_next_instance_of(klass) do |strategy|
            expect(strategy).to receive(:schedule).with(job, &block)
          end

          pause_control.schedule(&block)
        end.to yield_control
      end
    end

    it_behaves_like 'scheduling with pause control class', 'Zoekt'
  end

  describe '#perform' do
    it 'calls perform on the strategy' do
      expect do |block|
        expect_next_instance_of(Gitlab::SidekiqMiddleware::PauseControl::Strategies::Zoekt) do |strategy|
          expect(strategy).to receive(:perform).with(job, &block)
        end

        pause_control.perform(&block)
      end.to yield_control
    end

    it 'pauses job' do
      expect_next_instance_of(Gitlab::SidekiqMiddleware::PauseControl::Strategies::Zoekt) do |strategy|
        expect(strategy).to receive(:should_pause?).and_return(true)
      end

      expect { pause_control.perform }.to change {
        Gitlab::SidekiqMiddleware::PauseControl::PauseControlService.queue_size('TestPauseWorker')
      }.by(1)
    end
  end
end
