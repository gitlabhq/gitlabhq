# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::BackgroundOperation::Observability::EventLogger, feature_category: :database do
  describe '.log' do
    let(:logger) { described_class }
    let(:worker) { instance_double(Gitlab::Database::BackgroundOperation::Worker, id: [1, 100]) }
    let(:job) { instance_double(Gitlab::Database::BackgroundOperation::Job, id: [1, 100]) }

    it 'logs worker_transition events' do
      expect_next_instance_of(
        Gitlab::Database::BackgroundOperation::Observability::Events::WorkerTransitionEvent
      ) do |instance|
        expect(instance).to receive(:log)
      end

      logger.log(event: :worker_transition, record: worker, previous_state: :pending, new_state: :active)
    end

    it 'logs worker_optimization events' do
      expect_next_instance_of(
        Gitlab::Database::BackgroundOperation::Observability::Events::WorkerOptimizationEvent
      ) do |instance|
        expect(instance).to receive(:log)
      end

      logger.log(event: :worker_optimization, record: worker, old_batch_size: 1000, new_batch_size: 5000)
    end

    it 'logs job_transition events' do
      expect_next_instance_of(
        Gitlab::Database::BackgroundOperation::Observability::Events::JobTransitionEvent
      ) do |instance|
        expect(instance).to receive(:log)
      end

      logger.log(event: :job_transition, record: job, previous_state: :running, new_state: :succeeded)
    end

    it 'raises KeyError for unknown event types' do
      expect { logger.log(event: :unknown_event, record: nil) }.to raise_error(KeyError)
    end
  end
end
