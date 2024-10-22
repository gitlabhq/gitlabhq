# frozen_string_literal: true

require 'spec_helper'

# Gitlab::SidekiqSharding::ScheduledEnq does not need routing checks as it extends
# Sidekiq::Scheduled::Enq which internally uses Sidekiq.redis. That is expected of the poller.
RSpec.describe Gitlab::SidekiqSharding::ScheduledEnq, :allow_unrouted_sidekiq_calls,
  feature_category: :scalability do
  it 'extends Sidekiq::Scheduled::Enq' do
    expect(described_class <= ::Sidekiq::Scheduled::Enq).to eq(true)
  end

  describe '#enqueue_jobs' do
    let(:enq) { described_class.new(Sidekiq.default_configuration) }
    let(:job_hash) { { class: 'invalidclass', args: [], queue: 'default', store: 'main' } }
    let(:store_name) { 'main' }

    before do
      allow(Gitlab::SidekiqSharding::Router).to receive(:enabled?).and_return(true)
      allow(Feature).to receive(:enabled?).and_return(true)
      Sidekiq.redis { |c| c.zadd('schedule', [1000.0, Sidekiq.dump_json(job_hash)]) }
    end

    shared_examples 'uses sharding router' do
      it 'checks shard instance for job' do
        expect(Gitlab::SidekiqSharding::Router).to receive(:get_shard_instance).with(store_name).and_call_original

        enq.enqueue_jobs

        expect(Sidekiq.redis { |c| c.zcard('schedule') }).to eq(0)
      end
    end

    shared_examples 'updates queue key' do
      let(:sc) { instance_double(Sidekiq::Client) }
      before do
        allow(Sidekiq::Client).to receive(:new).and_call_original
        allow(Sidekiq::Client).to receive(:new).with(config: Sidekiq.default_configuration,
          pool: Gitlab::Redis::Queues.sidekiq_redis).and_return(sc)
      end

      it 'job hash contains updated queue key' do
        expect(sc).to receive(:push).with(hash_including({ 'queue' => queue_name }))

        enq.enqueue_jobs
      end
    end

    context 'with routing disabled' do
      before do
        allow(Gitlab::SidekiqSharding::Router).to receive(:enabled?).and_return(false)
      end

      it 'enqueues job using Sidekiq::client' do
        expect(Gitlab::SidekiqSharding::Router).not_to receive(:get_shard_instance).with(store_name)

        enq.enqueue_jobs

        expect(Sidekiq.redis { |c| c.zcard('schedule') }).to eq(0)
      end
    end

    context 'with invalid job hashes' do
      it_behaves_like 'uses sharding router'

      context 'with class that does not exist on this process' do
        let(:job_hash) { { class: 'invalidclass', args: [], queue: 'default', store: 'another_shard' } }
        let(:store_name) { 'another_shard' }

        it_behaves_like 'uses sharding router'
      end
    end

    context 'with classes not including ApplicationWorker' do
      let(:job_hash) { { class: Gitlab::SidekiqConfig::DummyWorker, args: [] } }

      it_behaves_like 'uses sharding router'
    end

    context 'with ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper classes' do
      let(:job_hash) { { class: ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper, args: [] } }
      let(:store_name) { 'queues_shard_test' }
      let(:queue_name) { 'test' }

      before do
        # simulate routing rules in config/gitlab.yml
        allow(ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper)
          .to receive(:get_sidekiq_options).and_return({ 'store' => store_name, 'queue' => queue_name })

        # skip label creation to avoid calling .get_shard_instance
        allow_next_instance_of(Gitlab::SidekiqMiddleware::ClientMetrics) do |mh|
          allow(mh).to receive(:create_labels).and_return({ boundary: "", destination_shard_redis: "",
external_dependencies: "", feature_category: "", queue: "", scheduling: "", urgency: "", worker: "" })
        end
      end

      it_behaves_like 'uses sharding router'
      it_behaves_like 'updates queue key'
    end

    context 'with ApplicationWorker classes' do
      let(:job_hash) { { class: Chaos::CpuSpinWorker, args: [], queue: 'default', store: 'main' } }
      let(:store_name) { 'queues_shard_test' }
      let(:queue_name) { 'test' }

      before do
        # simulate routing rules in config/gitlab.yml
        allow(Chaos::CpuSpinWorker).to receive(:get_sidekiq_options)
            .and_return({ 'store' => store_name, 'queue' => queue_name })

        # skip label creation to avoid calling .get_shard_instance
        allow_next_instance_of(Gitlab::SidekiqMiddleware::ClientMetrics) do |mh|
          allow(mh).to receive(:create_labels).and_return({ boundary: "", destination_shard_redis: "",
external_dependencies: "", feature_category: "", queue: "", scheduling: "", urgency: "", worker: "" })
        end
      end

      it_behaves_like 'uses sharding router'
      it_behaves_like 'updates queue key'

      context 'when worker does not have queue set' do
        let(:sc) { instance_double(Sidekiq::Client) }

        before do
          allow(Chaos::CpuSpinWorker).to receive(:get_sidekiq_options).and_return({ 'store' => store_name })
          allow(Sidekiq::Client).to receive(:new).and_call_original
        end

        it_behaves_like 'uses sharding router'

        it 'job hash does not contain updated queue key' do
          allow(Sidekiq::Client).to receive(:new).with(config: Sidekiq.default_configuration,
            pool: Gitlab::Redis::Queues.sidekiq_redis).and_return(sc)

          expect(sc).to receive(:push).with(hash_including({ 'queue' => 'default' }))

          enq.enqueue_jobs
        end
      end
    end
  end
end
