# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::ConcurrencyLimit::QueueManager,
  :clean_gitlab_redis_shared_state, feature_category: :global_search do
  let(:worker_class) do
    Class.new do
      def self.name
        'DummyWorker'
      end

      include ApplicationWorker
    end
  end

  let(:worker_class_name) { worker_class.name }

  let(:worker_context) do
    { 'correlation_id' => 'context_correlation_id',
      'meta.project' => 'gitlab-org/gitlab' }
  end

  let(:stored_context) do
    {
      "#{Gitlab::ApplicationContext::LOG_KEY}.project" => 'gitlab-org/gitlab',
      "correlation_id" => 'context_correlation_id'
    }
  end

  let(:worker_args) { [1, 2] }

  subject(:service) { described_class.new(worker_name: worker_class_name, prefix: 'some_prefix') }

  before do
    stub_const(worker_class_name, worker_class)
  end

  describe '#add_to_queue!' do
    subject(:add_to_queue!) { service.add_to_queue!(worker_args, worker_context) }

    it 'adds a job to the set' do
      expect { add_to_queue! }
        .to change { service.queue_size }
        .from(0).to(1)
    end

    it 'adds only one unique job to the set' do
      expect do
        2.times { add_to_queue! }
      end.to change { service.queue_size }.from(0).to(1)
    end

    it 'stores context information' do
      add_to_queue!

      Gitlab::Redis::SharedState.with do |r|
        set_key = service.redis_key
        stored_job = service.send(:deserialize, r.lrange(set_key, 0, -1).first)

        expect(stored_job['context']).to eq(stored_context)
      end
    end
  end

  describe '#has_jobs_in_queue?' do
    it 'uses queue_size' do
      expect { service.add_to_queue!(worker_args, worker_context) }
        .to change { service.has_jobs_in_queue? }
        .from(false).to(true)
    end
  end

  describe '#resume_processing!' do
    let(:jobs) { [[1], [2], [3]] }
    let(:setter) { instance_double('Sidekiq::Job::Setter') }

    it 'puts jobs back into the queue and respects order' do
      jobs.each do |j|
        service.add_to_queue!(j, worker_context)
      end

      expect(worker_class).to receive(:concurrency_limit_resume).twice.and_return(setter)
      expect(setter).to receive(:perform_async).with(1).ordered
      expect(setter).to receive(:perform_async).with(2).ordered
      expect(setter).not_to receive(:perform_async).with(3).ordered

      expect(Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance)
        .to receive(:resumed_log)
        .with(worker_class_name, [1])
      expect(Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance)
        .to receive(:resumed_log)
        .with(worker_class_name, [2])

      service.resume_processing!(limit: 2)
    end

    it 'drops a set after execution' do
      jobs.each do |j|
        service.add_to_queue!(j, worker_context)
      end

      expect(Gitlab::ApplicationContext).to receive(:with_raw_context)
        .with(stored_context)
        .exactly(jobs.count).times.and_call_original
      expect(worker_class).to receive(:concurrency_limit_resume).exactly(3).times.and_return(setter)
      expect(setter).to receive(:perform_async).exactly(jobs.count).times

      expect { service.resume_processing!(limit: jobs.count) }
        .to change { service.has_jobs_in_queue? }.from(true).to(false)
    end
  end
end
