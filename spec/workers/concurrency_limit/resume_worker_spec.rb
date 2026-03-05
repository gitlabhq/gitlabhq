# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ConcurrencyLimit::ResumeWorker, feature_category: :scalability do
  subject(:worker) { described_class.new }

  let(:worker_with_concurrency_limit) { Releases::CreateEvidenceWorker }
  let(:concurrent_workers) { 5 }

  describe '#perform' do
    before do
      allow(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).to receive(:resume_processing!)
      allow(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
        .to receive(:concurrent_worker_count).and_return(concurrent_workers)
    end

    context 'when worker_name is absent' do
      subject(:perform) { worker.perform }

      context 'when worker is being limited' do
        before do
          allow(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).to receive(:queue_size)
            .and_return(0)
          allow(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).to receive(:queue_size)
            .with(worker_with_concurrency_limit.name).and_return(10000)
        end

        it 'schedules workers' do
          expect(Sidekiq::Client).to receive(:push).with(
            'class' => described_class,
            'args' => [worker_with_concurrency_limit.name],
            'queue' => ::Gitlab::SidekiqConfig::WorkerRouter.global.route(worker_with_concurrency_limit)
          )

          perform
        end

        context 'when worker is routed to another queue' do
          before do
            allow(::Gitlab::SidekiqConfig::WorkerRouter.global).to receive(:route)
                                                                     .with(worker_with_concurrency_limit)
                                                                     .and_return("other_queue")
          end

          it 'schedules the worker to the other queue' do
            expect(Sidekiq::Client).to receive(:push).with(
              'class' => described_class,
              'args' => [worker_with_concurrency_limit.name],
              'queue' => "other_queue"
            )

            perform
          end
        end

        context 'when worker is routed to another shard' do
          let(:test_shard_name) { 'queues_shard_test' }
          let(:shard_config) { { test_shard_name => { 'url' => 'redis://dummyhost' } } }

          before do
            redis_class = Gitlab::Redis::Queues.send(:create_shard_class, test_shard_name,
              shard_config)

            test_redis_params = Gitlab::Redis::Queues.params.deep_dup
            # change only the db so the test can run in both CI and local.
            test_redis_params[:db] = (test_redis_params[:db].to_i + 1) % 15
            redis_class.instance_variable_set(:@params, test_redis_params.freeze)

            allow(Gitlab::Redis::Queues).to receive(:instances).and_return({
              test_shard_name => redis_class,
              'main' => Gitlab::Redis::Queues
            })

            # set worker to use the test shard
            allow(worker_with_concurrency_limit).to receive(:get_sidekiq_options)
                                                      .and_return({ "store" => test_shard_name })

            allow(Feature).to receive(:enabled?).and_call_original
            allow(Feature).to receive(:enabled?)
                                .with(:sidekiq_route_to_queues_shard_test, default_enabled_if_undefined: false,
                                  type: :worker)
                                .and_return(true)
            allow(::Gitlab::SidekiqConfig::WorkerRouter.global).to receive(:route)
                                                                     .and_call_original
            allow(::Gitlab::SidekiqConfig::WorkerRouter.global).to receive(:route)
                                                                     .with(worker_with_concurrency_limit)
                                                                     .and_return("other_queue")
            with_shard_client do
              Sidekiq::Queue.new("other_queue").clear
            end
          end

          after do
            with_shard_client do
              Sidekiq::Queue.new("other_queue").clear
            end
          end

          def with_shard_client(&block)
            _, pool = Gitlab::SidekiqSharding::Router.get_shard_instance(test_shard_name)
            Sidekiq::Client.via(pool, &block)
          end

          it "schedules a job to the worker's sharded redis store" do
            Sidekiq::Testing.disable! do
              perform

              with_shard_client do
                queue = Sidekiq::Queue.new("other_queue")
                expect(queue.size).to eq(1)
                expect(queue.first['class']).to eq(described_class.name)
                expect(queue.first['args']).to eq([worker_with_concurrency_limit.name])
              end
            end
          end
        end
      end

      context 'when there are no jobs in the queue' do
        before do
          allow(worker_with_concurrency_limit).to receive(:get_concurrency_limit).and_return(10)
          allow(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).to receive(:queue_size)
            .and_return(0)
        end

        it 'does not schedule workers' do
          expect(described_class).not_to receive(:perform_async)

          perform
        end
      end

      context 'when worker is not enabled to use concurrency limit middleware' do
        before do
          allow(worker_with_concurrency_limit).to receive(:get_concurrency_limit).and_return(0)
          allow(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).to receive(:queue_size)
            .and_return(0)
        end

        it 'does not schedule workers' do
          expect(described_class).not_to receive(:perform_async)

          perform
        end
      end
    end

    context 'when worker_name is present' do
      subject(:perform) { worker.perform(worker_with_concurrency_limit.name) }

      context 'when there are no jobs in the queue' do
        before do
          allow(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).to receive_messages(
            current_limit: 10, queue_size: 0)
        end

        it 'does nothing' do
          expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
            .not_to receive(:resume_processing!)

          perform
        end

        it 'does not log worker concurrency limit stats' do
          expect(Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance).not_to receive(:worker_stats_log)

          perform
        end
      end

      context 'when there are jobs in the queue' do
        before do
          allow(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).to receive(:queue_size)
            .and_return(0)
          allow(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).to receive(:queue_size)
            .with(worker_with_concurrency_limit.name).and_return(10000)
        end

        it 'logs worker concurrency limit stats' do
          # note that we stub all workers limit to 0 except worker_with_concurrency_limit
          expect(Gitlab::SidekiqLogging::ConcurrencyLimitLogger.instance).to receive(:worker_stats_log).once

          perform
        end

        it 'resumes processing' do
          expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
            .to receive(:resume_processing!)
                  .with(worker_with_concurrency_limit.name)
                  .and_return(10)

          perform

          expect(worker.logging_extras).to eq({ "extra.concurrency_limit_resume_worker.resumed_jobs" => 10 })
        end

        context 'when current_limit is present in Redis' do
          before do
            Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService
              .set_current_limit!(worker_with_concurrency_limit.name, limit: 10)
          end

          it 'resumes processing based on limit in Redis' do
            expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
              .to receive(:resume_processing!)
                    .with(worker_with_concurrency_limit.name)

            perform
          end
        end

        context 'when limit is negative' do
          before do
            allow(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).to receive(:current_limit)
                                                                                             .and_return(-1)
          end

          it 'does not schedule any workers' do
            expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
              .not_to receive(:resume_processing!)
            expect(described_class).not_to receive(:perform_in)

            perform
          end
        end

        context 'when limit is not set' do
          before do
            allow(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService).to receive(:current_limit)
                                                                                             .and_return(0)
            allow(Gitlab::SidekiqConfig::WorkerRouter.global).to receive(:route).with(worker_with_concurrency_limit)
                                                                                .and_return('another_queue')
          end

          after do
            Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls { Sidekiq::ScheduledSet.new.clear }
          end

          it 'resumes processing' do
            expect(Gitlab::SidekiqMiddleware::ConcurrencyLimit::ConcurrencyLimitService)
              .to receive(:resume_processing!)
                .with(worker_with_concurrency_limit.name)
            expect(Sidekiq::Client).to receive(:enqueue_to_in).with('another_queue', described_class::RESCHEDULE_DELAY,
              described_class, worker_with_concurrency_limit.name)

            perform
          end

          it 'schedules the job to another queue' do
            Sidekiq::Testing.disable! { perform }

            Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
              expect(Sidekiq::ScheduledSet.new.size).to eq(1)
              job = Sidekiq::ScheduledSet.new.first
              expect(job.queue).to eq('another_queue')
              expect(job.klass).to eq('ConcurrencyLimit::ResumeWorker')
              expect(job.args).to eq([worker_with_concurrency_limit.name])
            end
          end
        end
      end
    end
  end
end
