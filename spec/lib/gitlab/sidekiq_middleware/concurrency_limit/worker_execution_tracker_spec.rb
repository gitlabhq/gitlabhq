# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkerExecutionTracker,
  :clean_gitlab_redis_queues_metadata, feature_category: :global_search do
  let(:worker_class) do
    Class.new do
      def self.name
        'DummyWorker'
      end

      include ApplicationWorker
    end
  end

  let(:worker_class_name) { worker_class.name }

  let(:redis_key_prefix) { 'random_prefix' }

  let(:sidekiq_pid) { 'proc-abc' }
  let(:sidekiq_tid) { 'proc-abc' }

  let(:tracking_hash) { "#{redis_key_prefix}:{#{worker_class_name.underscore}}:executing" }
  let(:tracking_elem) { "#{sidekiq_pid}:tid:#{sidekiq_tid}" }

  subject(:service) { described_class.new(worker_name: worker_class_name, prefix: redis_key_prefix) }

  before do
    stub_const(worker_class_name, worker_class)

    Thread.current[:sidekiq_capsule] = Sidekiq::Capsule.new('test', Sidekiq.default_configuration)
    allow(Thread.current[:sidekiq_capsule]).to receive(:identity).and_return(sidekiq_pid)
    allow(service).to receive(:sidekiq_tid).and_return(sidekiq_tid)
  end

  describe '#track_execution_start' do
    subject(:track_execution_start) { service.track_execution_start }

    it 'writes to Redis hash and string' do
      track_execution_start

      Gitlab::Redis::QueuesMetadata.with do |c|
        expect(c.hexists(tracking_hash, tracking_elem)).to eq(true)
      end
    end

    context 'when Thread.current[:sidekiq_capsule] is missing' do
      before do
        Thread.current[:sidekiq_capsule] = nil
      end

      it 'exits early without writing to redis' do
        track_execution_start

        Gitlab::Redis::QueuesMetadata.with do |c|
          expect(c.hexists(tracking_hash, tracking_elem)).to eq(false)
        end
      end
    end
  end

  describe '#track_execution_end' do
    subject(:track_execution_end) { service.track_execution_end }

    before do
      service.track_execution_start
    end

    it 'clears to Redis hash and string' do
      Gitlab::Redis::QueuesMetadata.with do |c|
        expect { track_execution_end }
          .to change { c.hexists(tracking_hash, tracking_elem) }.from(true).to(false)
      end
    end

    context 'when Thread.current[:sidekiq_capsule] is missing' do
      before do
        Thread.current[:sidekiq_capsule] = nil
      end

      it 'exits early without writing to redis' do
        Gitlab::Redis::QueuesMetadata.with do |c|
          expect(c.hexists(tracking_hash, tracking_elem)).to eq(true)
          track_execution_end
          expect(c.hexists(tracking_hash, tracking_elem)).to eq(true)
        end
      end
    end
  end

  describe '#concurrent_worker_count' do
    let(:size) { 10 }

    subject(:concurrent_worker_count) { service.concurrent_worker_count }

    before do
      Gitlab::Redis::QueuesMetadata.with do |c|
        c.hset(tracking_hash, (1..size).flat_map { |i| [i, i] })
      end
    end

    it 'returns hash size' do
      expect(concurrent_worker_count).to eq(size)
    end

    context 'with empty hash' do
      before do
        Gitlab::Redis::QueuesMetadata.with { |c| c.del(tracking_hash) }
      end

      it 'returns 0' do
        expect(concurrent_worker_count).to eq(0)
      end
    end
  end

  describe '#cleanup_stale_trackers' do
    let(:dangling_tid) { 4567 }
    let(:long_running_tid) { 5678 }
    let(:invalid_process_thread_id) { 'proc-abc::4567' }
    let(:dangling_process_thread_id) { 'proc-abc:tid:4567' }
    let(:long_running_process_thread_id) { 'proc-abc:tid:5678' }

    # Format from https://github.com/sidekiq/sidekiq/blob/v7.2.4/lib/sidekiq/api.rb#L1180
    # The tid field in the `{pid}:work` hash contains a hash of 'payload' -> job hash.
    def generate_sidekiq_hash(worker)
      job_hash = { 'payload' => ::Gitlab::Json.dump({
        'class' => worker,
        'created_at' => Time.now.to_f - described_class::TRACKING_KEY_TTL
      }) }

      Sidekiq.dump_json(job_hash)
    end

    subject(:cleanup_stale_trackers) { service.cleanup_stale_trackers }

    context 'when hash is valid' do
      before do
        Gitlab::Redis::QueuesMetadata.with do |r|
          # element should not be deleted since it is within the ttl
          r.hset(tracking_hash, tracking_elem, Time.now.utc.tv_sec - (0.1 * described_class::TRACKING_KEY_TTL.to_i))

          # element should not be deleted since it is a long running process
          r.hset(tracking_hash, long_running_process_thread_id,
            Time.now.utc.tv_sec - (2 * described_class::TRACKING_KEY_TTL.to_i))

          # element should be deleted since hash value is invalid
          r.hset(tracking_hash, invalid_process_thread_id,
            Time.now.utc.tv_sec - (2 * described_class::TRACKING_KEY_TTL.to_i))

          # element should be deleted since it is a long running process
          # but stale as the thread is executing another worker now
          r.hset(tracking_hash, dangling_process_thread_id,
            Time.now.utc.tv_sec - (2 * described_class::TRACKING_KEY_TTL.to_i))
        end

        Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
          Sidekiq.redis do |r|
            r.hset("proc-abc:work", long_running_tid, generate_sidekiq_hash(worker_class_name))
            r.hset("proc-abc:work", dangling_process_thread_id, generate_sidekiq_hash('otherworker'))
          end
        end
      end

      it 'only cleans up dangling keys' do
        expect { cleanup_stale_trackers }.to change { service.concurrent_worker_count }.from(4).to(2)
      end
    end

    context 'when hash is invalid' do
      let(:invalid_hash) { 'invalid' }

      before do
        Gitlab::Redis::QueuesMetadata.with do |r|
          r.hset(tracking_hash, long_running_process_thread_id,
            Time.now.utc.tv_sec - (2 * described_class::TRACKING_KEY_TTL.to_i))
        end

        Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
          Sidekiq.redis do |r|
            r.hset("proc-abc:work", long_running_tid, invalid_hash)
          end
        end
      end

      it 'tracks exception' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(instance_of(JSON::ParserError),
          worker_class: 'DummyWorker')

        expect { cleanup_stale_trackers }.to change { service.concurrent_worker_count }.from(1).to(0)
      end
    end
  end
end
