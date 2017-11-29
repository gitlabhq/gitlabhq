require 'spec_helper'

describe Gitlab::SidekiqVersioning, :sidekiq, :redis do
  let(:foo_worker) do
    Class.new do
      def self.name
        'FooWorker'
      end

      include ApplicationWorker
    end
  end

  let(:bar_worker) do
    Class.new do
      def self.name
        'BarWorker'
      end

      include ApplicationWorker

      version 2
    end
  end

  before do
    allow(Gitlab::SidekiqConfig).to receive(:workers).and_return([foo_worker, bar_worker])
    allow(Gitlab::SidekiqConfig).to receive(:worker_queues).and_return([foo_worker.queue, bar_worker.queue])
    allow(Gitlab::SidekiqConfig).to receive(:workers_by_queue).and_return({ 'foo' => foo_worker, 'bar' => bar_worker })
    allow(Gitlab::SidekiqConfig).to receive(:redis_queues).and_return(%w[foo foo:v1 bar:v1 bar:v3 bar:v])
  end

  describe '.install!' do
    it 'prepends SidekiqVersioning::Manager into Sidekiq::Manager' do
      described_class.install!

      expect(Sidekiq::Manager).to include(Gitlab::SidekiqVersioning::Manager)
    end

    it 'prepends SidekiqVersioning::JobRetry into Sidekiq::JobRetry' do
      described_class.install!

      expect(Sidekiq::JobRetry).to include(Gitlab::SidekiqVersioning::JobRetry)
    end

    it 'adds the SidekiqVersioning::Middleware Sidekiq server middleware' do
      described_class.install!

      expect(Sidekiq.server_middleware.entries.map(&:klass)).to include(Gitlab::SidekiqVersioning::Middleware)
    end

    it 'registers all versionless and versioned queues with Redis' do
      described_class.install!

      queues = Sidekiq::Queue.all.map(&:name)
      expect(queues).to include('foo')
      expect(queues).to include('foo:v0')
      expect(queues).to include('bar')
      expect(queues).to include('bar:v2')
    end
  end

  describe '.requeue_unsupported_job' do
    let(:job) do
      {
        'queue' => bar_worker.queue,
        'class' => bar_worker.name,
        'args' => [1, 2, 3]
      }
    end

    let(:queue) { bar_worker.queue }

    around do |example|
      Sidekiq::Testing.fake! { example.run }
    end

    def requeue_unsupported_job!
      worker = bar_worker.new

      # Normally the responsibility of Gitlab::SidekiqVersioning::Middleware
      worker.job_version = job['version']

      described_class.requeue_unsupported_job(worker, job, queue)
    end

    def expect_requeue_to_version_queue(version_queue)
      expect { requeue_unsupported_job! }.to change(Sidekiq::Queues[version_queue], :size).by(1)

      last_job = Sidekiq::Queues[version_queue].last

      expect(last_job['original_queue']).to eq(queue)
      expect(last_job['requeued_at']).not_to be_nil
      expect(last_job['queue']).to eq(version_queue)
    end

    context 'when the job does not have a version' do
      it 'returns false' do
        expect(requeue_unsupported_job!).to be_falsey
      end
    end

    context 'when the job has a version' do
      context 'when the worker supports the version' do
        before do
          job['version'] = bar_worker.version
        end

        it 'returns false' do
          expect(requeue_unsupported_job!).to be_falsey
        end
      end

      context 'when there is no worker or the worker does not support the version' do
        before do
          job['version'] = 3
        end

        context 'when the job has already been requeued' do
          before do
            job['requeued_at'] = Time.now
          end

          it 'returns false' do
            expect(requeue_unsupported_job!).to be_falsey
          end
        end

        context 'when the job has not been requeued yet' do
          context 'when higher version queues exist' do
            before do
              allow(Gitlab::SidekiqConfig).to receive(:redis_queues).and_return(%W[#{queue}:v2 #{queue}:v4 #{queue}:v5])
            end

            it 'requeues the job on the lowest version queue for a higher version' do
              expect_requeue_to_version_queue("#{queue}:v4")
            end

            it 'returns true' do
              expect(requeue_unsupported_job!).to be_truthy
            end
          end

          context 'when no higher version queues exists' do
            before do
              allow(Gitlab::SidekiqConfig).to receive(:redis_queues).and_return(%W[#{queue}:v2])
            end

            it 'requeues the job on the queue for the job version' do
              expect_requeue_to_version_queue("#{queue}:v3")
            end

            it 'returns true' do
              expect(requeue_unsupported_job!).to be_truthy
            end
          end
        end
      end
    end
  end

  describe '.queues_with_versions' do
    it 'returns versionless and versioned queues for the queues in question' do
      expect(described_class.queues_with_versions(%w[foo bar baz])).to match_array(%w[foo foo:v0 bar bar:v1 bar:v2 baz])
    end
  end

  describe '.queue_versions' do
    it 'returns versions for the queue in question' do
      expect(described_class.queue_versions('bar')).to match_array([1, 3])
    end
  end
end
