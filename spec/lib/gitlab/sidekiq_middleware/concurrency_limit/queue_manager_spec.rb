# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::ConcurrencyLimit::QueueManager,
  :clean_gitlab_redis_shared_state, :request_store, feature_category: :global_search do
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

  let(:job) { { 'args' => [1, 2] } }
  let(:job_with_wal_locations) do
    { 'args' => [1, 2], 'wal_locations' => { 'main' => '0/D525E3A8', 'ci' => '0/D525E3A8' } }
  end

  subject(:service) { described_class.new(worker_name: worker_class_name, prefix: 'some_prefix') }

  before do
    stub_const(worker_class_name, worker_class)
  end

  describe '#add_to_queue!' do
    subject(:add_to_queue!) { service.add_to_queue!(job, worker_context) }

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

    context 'with wal locations' do
      subject(:add_to_queue!) { service.add_to_queue!(job_with_wal_locations, worker_context) }

      it 'stores wal locations' do
        add_to_queue!

        Gitlab::Redis::SharedState.with do |r|
          set_key = service.redis_key
          stored_job = service.send(:deserialize, r.lrange(set_key, 0, -1).first)

          expect(stored_job['wal_locations']).to eq(job_with_wal_locations['wal_locations'])
        end
      end
    end
  end

  describe '#has_jobs_in_queue?' do
    it 'uses queue_size' do
      expect { service.add_to_queue!(job, worker_context) }
        .to change { service.has_jobs_in_queue? }
        .from(false).to(true)
    end
  end

  describe '#resume_processing!' do
    let(:wal_locations) { { 'main' => '0/D525E3A8', 'ci' => '0/D525E3A8' } }
    let(:jobs) do
      [
        { 'args' => [1], 'wal_locations' => wal_locations },
        { 'args' => [2], 'wal_locations' => wal_locations },
        { 'args' => [3], 'wal_locations' => wal_locations }
      ]
    end

    let(:buffered_at) { Time.now.utc }
    let(:metadata_queue) do
      queue = Queue.new
      2.times do
        queue.push({ 'concurrency_limit_buffered_at' => buffered_at.to_f,
                     'concurrency_limit_resume' => true,
                     'wal_locations' => wal_locations }.merge(stored_context))
      end

      queue
    end

    let(:metadata_key) { service.metadata_key }

    subject(:stored_metadata_queue) { Gitlab::SafeRequestStore.read(metadata_key) }

    before do
      service.remove_instance_variable(:@lease) if service.instance_variable_defined?(:@lease)
      travel_to(buffered_at) do
        jobs.each do |j|
          service.add_to_queue!(j, worker_context)
        end
      end
    end

    it 'puts jobs back into the queue and respects order' do
      expect_next_instance_of(Gitlab::ExclusiveLease) do |el|
        expect(el).to receive(:try_obtain).and_call_original
      end

      expect(Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance)
        .to receive(:resumed_log)
              .with(worker_class_name, [[1], [2]])
      expect(Gitlab::SafeRequestStore).to receive(:write).with(
        metadata_key,
        kind_of(Queue)
      ).and_call_original
      expect(worker_class).to receive(:bulk_perform_async).with([[1], [2]])

      service.resume_processing!(limit: 2)

      until metadata_queue.empty?
        expected = metadata_queue.pop
        actual = stored_metadata_queue.pop
        expect(actual['concurrency_limit_buffered_at']).to be_within(1.second)
                                                       .of(expected['concurrency_limit_buffered_at'])
        expect(actual.except('concurrency_limit_buffered_at')).to eq(expected.except('concurrency_limit_buffered_at'))
      end

      expect(stored_metadata_queue).to be_empty
    end

    it 'drops a set after execution' do
      expect_next_instance_of(Gitlab::ExclusiveLease) do |el|
        expect(el).to receive(:try_obtain).and_call_original
      end

      expect(worker_class).to receive(:bulk_perform_async).with([[1], [2], [3]])
      expect { service.resume_processing!(limit: jobs.count) }
        .to change { service.has_jobs_in_queue? }.from(true).to(false)
    end

    context 'when processing more than batch size' do
      before do
        stub_const("#{described_class}::RESUME_PROCESSING_BATCH_SIZE", 1)
      end

      it 'pushes the jobs in batches' do
        jobs.each do |job|
          expect(worker_class).to receive(:bulk_perform_async).with([job['args']]).ordered
        end

        service.resume_processing!(limit: jobs.count)
      end
    end

    context 'when exclusive lease is already being held' do
      before do
        service.exclusive_lease.try_obtain
      end

      it 'does not perform enqueue' do
        travel_to(buffered_at) do
          jobs.each do |j|
            service.add_to_queue!(j, worker_context)
          end
        end

        expect(worker_class).not_to receive(:concurrency_limit_resume)

        service.resume_processing!(limit: 2)
      end
    end
  end
end
