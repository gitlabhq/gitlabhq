# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::PauseControl::PauseControlService, :clean_gitlab_redis_shared_state, feature_category: :global_search do
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
    { "#{Gitlab::ApplicationContext::LOG_KEY}.project" => 'gitlab-org/gitlab' }
  end

  let(:worker_args) { [1, 2] }

  subject { described_class.new(worker_class_name) }

  before do
    stub_const(worker_class_name, worker_class)
  end

  describe '.add_to_waiting_queue!' do
    it 'calls an instance method' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:add_to_waiting_queue!).with(worker_args, worker_context)
      end

      described_class.add_to_waiting_queue!(worker_class_name, worker_args, worker_context)
    end
  end

  describe '.has_jobs_in_waiting_queue?' do
    it 'calls an instance method' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:has_jobs_in_waiting_queue?)
      end

      described_class.has_jobs_in_waiting_queue?(worker_class_name)
    end
  end

  describe '.resume_processing!' do
    it 'calls an instance method' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:resume_processing!)
      end

      described_class.resume_processing!(worker_class_name)
    end
  end

  describe '.queue_size' do
    it 'reports the queue size' do
      expect(described_class.queue_size(worker_class_name)).to eq(0)

      subject.add_to_waiting_queue!(worker_args, worker_context)

      expect(described_class.queue_size(worker_class_name)).to eq(1)

      expect { subject.resume_processing! }.to change { described_class.queue_size(worker_class_name) }.by(-1)
    end
  end

  describe '#add_to_waiting_queue!' do
    it 'adds a job to the set' do
      expect { subject.add_to_waiting_queue!(worker_args, worker_context) }
        .to change { subject.queue_size }
        .from(0).to(1)
    end

    it 'adds only one unique job to the set' do
      expect do
        2.times { subject.add_to_waiting_queue!(worker_args, worker_context) }
      end.to change { subject.queue_size }.from(0).to(1)
    end

    it 'only stores `project` context information' do
      subject.add_to_waiting_queue!(worker_args, worker_context)

      subject.send(:with_redis) do |r|
        set_key = subject.send(:redis_set_key)
        stored_job = subject.send(:deserialize, r.zrange(set_key, 0, -1).first)

        expect(stored_job['context']).to eq(stored_context)
      end
    end
  end

  describe '#has_jobs_in_waiting_queue?' do
    it 'checks set existence' do
      expect { subject.add_to_waiting_queue!(worker_args, worker_context) }
        .to change { subject.has_jobs_in_waiting_queue? }
        .from(false).to(true)
    end
  end

  describe '#resume_processing!' do
    let(:jobs) { [[1], [2], [3]] }

    it 'puts jobs back into the queue and respects order' do
      # We stub this const to test at least a couple of loop iterations
      stub_const("#{described_class}::LIMIT", 2)

      jobs.each do |j|
        subject.add_to_waiting_queue!(j, worker_context)
      end

      expect(worker_class).to receive(:perform_async).with(1).ordered
      expect(worker_class).to receive(:perform_async).with(2).ordered
      expect(worker_class).not_to receive(:perform_async).with(3).ordered

      expect(Gitlab::SidekiqLogging::PauseControlLogger.instance).to receive(:resumed_log).with(worker_class_name, [1])
      expect(Gitlab::SidekiqLogging::PauseControlLogger.instance).to receive(:resumed_log).with(worker_class_name, [2])

      subject.resume_processing!
    end

    it 'drops a set after execution' do
      jobs.each do |j|
        subject.add_to_waiting_queue!(j, worker_context)
      end

      expect(Gitlab::ApplicationContext).to receive(:with_raw_context)
        .with(stored_context)
        .exactly(jobs.count).times.and_call_original
      expect(worker_class).to receive(:perform_async).exactly(jobs.count).times

      expect { subject.resume_processing! }.to change { subject.has_jobs_in_waiting_queue? }.from(true).to(false)
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
      expect { subject.add_to_waiting_queue!(worker_args, worker_context) }
        .to change { subject.queue_size }
        .from(0).to(1)

      expect { other_subject.add_to_waiting_queue!(worker_args, worker_context) }
        .to change { other_subject.queue_size }
        .from(0).to(1)

      expect { subject.resume_processing! }.to change { subject.has_jobs_in_waiting_queue? }
        .from(true).to(false)

      expect { other_subject.resume_processing! }.to change { other_subject.has_jobs_in_waiting_queue? }
        .from(true).to(false)
    end
  end
end
