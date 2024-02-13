# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService, :clean_gitlab_redis_shared_state, feature_category: :global_search do
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

  subject(:service) { described_class.new(worker_class_name) }

  before do
    stub_const(worker_class_name, worker_class)
  end

  describe '.add_to_queue!' do
    subject(:add_to_queue!) { described_class.add_to_queue!(worker_class_name, worker_args, worker_context) }

    it 'calls an instance method' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:add_to_queue!).with(worker_args, worker_context)
      end

      add_to_queue!
    end
  end

  describe '.has_jobs_in_queue?' do
    it 'calls an instance method' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:has_jobs_in_queue?)
      end

      described_class.has_jobs_in_queue?(worker_class_name)
    end
  end

  describe '.resume_processing!' do
    subject(:resume_processing!) { described_class.resume_processing!(worker_class_name, limit: 10) }

    it 'calls an instance method' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:resume_processing!)
      end

      resume_processing!
    end
  end

  describe '.queue_size' do
    it 'reports the queue size' do
      expect(described_class.queue_size(worker_class_name)).to eq(0)

      service.add_to_queue!(worker_args, worker_context)

      expect(described_class.queue_size(worker_class_name)).to eq(1)

      expect { service.resume_processing!(limit: 1) }.to change { described_class.queue_size(worker_class_name) }.by(-1)
    end
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

      service.send(:with_redis) do |r|
        set_key = service.send(:redis_key)
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
    let(:expected_context) { stored_context.merge(related_class: described_class.name) }

    it 'puts jobs back into the queue and respects order' do
      jobs.each do |j|
        service.add_to_queue!(j, worker_context)
      end

      expect(worker_class).to receive(:perform_async).with(1).ordered
      expect(worker_class).to receive(:perform_async).with(2).ordered
      expect(worker_class).not_to receive(:perform_async).with(3).ordered

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
        .with(expected_context)
        .exactly(jobs.count).times.and_call_original
      expect(worker_class).to receive(:perform_async).exactly(jobs.count).times

      expect { service.resume_processing!(limit: jobs.count) }
        .to change { service.has_jobs_in_queue? }.from(true).to(false)
    end
  end

  context 'with concurrent changes to different queues' do
    let(:second_worker_class) do
      Class.new do
        def self.name
          'SecondDummyIndexingWorker'
        end

        include ApplicationWorker
      end
    end

    let(:other_subject) { described_class.new(second_worker_class.name) }

    before do
      stub_const(second_worker_class.name, second_worker_class)
    end

    it 'allows to use queues independently of each other' do
      expect { service.add_to_queue!(worker_args, worker_context) }
        .to change { service.queue_size }
        .from(0).to(1)

      expect { other_subject.add_to_queue!(worker_args, worker_context) }
        .to change { other_subject.queue_size }
        .from(0).to(1)

      expect { service.resume_processing!(limit: 1) }.to change { service.has_jobs_in_queue? }
        .from(true).to(false)

      expect { other_subject.resume_processing!(limit: 1) }.to change { other_subject.has_jobs_in_queue? }
        .from(true).to(false)
    end
  end
end
