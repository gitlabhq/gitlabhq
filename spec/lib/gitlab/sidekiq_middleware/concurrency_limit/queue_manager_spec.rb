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

      concurrency_limit -> { 2 }
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
    let(:metadata_key) { service.metadata_key }
    let(:expected_metadata) do
      { 'concurrency_limit_buffered_at' => be_within(1.second).of(buffered_at.to_f),
        'concurrency_limit_resume' => true,
        'wal_locations' => wal_locations }.merge(stored_context)
    end

    before do
      service.remove_instance_variable(:@lease) if service.instance_variable_defined?(:@lease)
      travel_to(buffered_at) do
        jobs.each_with_index do |j, index|
          service.add_to_queue!(j, worker_context.merge({ "index" => index + 1 }))
        end
      end
    end

    shared_examples 'resumes jobs respecting concurrency limit' do
      it 'puts jobs back into the queue and respects order' do
        expect_next_instance_of(Gitlab::ExclusiveLease) do |el|
          expect(el).to receive(:try_obtain).and_call_original
        end

        expect(Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance)
          .to receive(:resumed_log)
                .with(worker_class_name, [[1], [2]]).ordered
        expect(Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance)
          .to receive(:resumed_log)
                .with(worker_class_name, [[3]]).ordered
        expect(Gitlab::SafeRequestStore).to receive(:write).with(
          metadata_key,
          kind_of(Queue)
        ) do |_key, queue|
          job1 = queue.pop
          expect(job1).to match(expected_metadata.merge({ "index" => 1 }))
          job2 = queue.pop
          expect(job2).to match(expected_metadata.merge({ "index" => 2 }))
        end

        expect(Gitlab::SafeRequestStore).to receive(:write).with(
          metadata_key,
          kind_of(Queue)
        ) do |_key, queue|
          job3 = queue.pop
          expect(job3).to match(expected_metadata.merge({ "index" => 3 }))
        end

        expect(worker_class).to receive(:bulk_perform_async).with([[1], [2]])
        expect(worker_class).to receive(:bulk_perform_async).with([[3]])

        resumed = service.resume_processing!

        expect(resumed).to eq(3)
      end
    end

    it_behaves_like 'resumes jobs respecting concurrency limit'

    it 'drops a set after execution' do
      expect_next_instance_of(Gitlab::ExclusiveLease) do |el|
        expect(el).to receive(:try_obtain).and_call_original
      end

      expect(worker_class).to receive(:bulk_perform_async).with([[1], [2]])
      expect(worker_class).to receive(:bulk_perform_async).with([[3]])
      expect { service.resume_processing! }
        .to change { service.has_jobs_in_queue? }.from(true).to(false)
    end

    context 'when processing longer than deadline' do
      let(:deadline) { instance_double(ActiveSupport::TimeWithZone) }

      before do
        allow(described_class::MAX_PROCESSING_TIME).to receive(:from_now).and_return(deadline)
        allow(deadline).to receive(:future?).and_return(true, false)
      end

      it 'stops processing after the deadline' do
        expect_next_instance_of(Gitlab::ExclusiveLease) do |el|
          expect(el).to receive(:try_obtain).and_call_original
        end

        resumed = service.resume_processing!

        expect(resumed).to eq(2)
        expect(service.queue_size).to eq(1)
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

        service.resume_processing!
      end
    end

    context 'when worker limit is 0' do
      before do
        worker_class.concurrency_limit -> { 0 }
        stub_const("#{described_class}::MAX_BATCH_SIZE", 1)
      end

      it 'resumes at MAX_BATCH_SIZE per iteration' do
        expect_next_instance_of(Gitlab::ExclusiveLease) do |el|
          expect(el).to receive(:try_obtain).and_call_original
        end

        expect(worker_class).to receive(:bulk_perform_async) do |args|
          expect(args.size).to eq(1)
        end.exactly(3).times

        service.resume_processing!
      end
    end
  end
end
