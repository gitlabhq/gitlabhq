# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::Database::Migrations::SidekiqHelpers do
  let(:model) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  describe "sidekiq migration helpers", :redis do
    let(:worker) do
      Class.new do
        include Sidekiq::Worker

        sidekiq_options queue: "test"

        def self.name
          "WorkerClass"
        end
      end
    end

    let(:worker_two) do
      Class.new do
        include Sidekiq::Worker

        sidekiq_options queue: "test_two"

        def self.name
          "WorkerTwoClass"
        end
      end
    end

    let(:same_queue_different_worker) do
      Class.new do
        include Sidekiq::Worker

        sidekiq_options queue: "test"

        def self.name
          "SameQueueDifferentWorkerClass"
        end
      end
    end

    let(:unrelated_worker) do
      Class.new do
        include Sidekiq::Worker

        sidekiq_options queue: "unrelated"

        def self.name
          "UnrelatedWorkerClass"
        end
      end
    end

    before do
      stub_const(worker.name, worker)
      stub_const(worker_two.name, worker_two)
      stub_const(unrelated_worker.name, unrelated_worker)
      stub_const(same_queue_different_worker.name, same_queue_different_worker)
    end

    describe "#sidekiq_remove_jobs", :clean_gitlab_redis_queues do
      def clear_queues
        Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
          Sidekiq::Queue.new("test").clear
          Sidekiq::Queue.new("test_two").clear
          Sidekiq::Queue.new("unrelated").clear
          Sidekiq::RetrySet.new.clear
          Sidekiq::ScheduledSet.new.clear
        end
      end

      around do |example|
        clear_queues
        Sidekiq::Testing.disable!(&example)
        clear_queues
      end

      context 'when inside a transaction' do
        it 'raises RuntimeError' do
          expect(model).to receive(:transaction_open?).and_return(true)

          expect { model.sidekiq_remove_jobs(job_klasses: [worker.name]) }
            .to raise_error(RuntimeError)
        end
      end

      context 'when outside a transaction' do
        before do
          allow(model).to receive(:transaction_open?).and_return(false)
          allow(model).to receive(:disable_statement_timeout).and_call_original
        end

        context "when the constant is not defined" do
          it "doesn't try to delete it" do
            my_non_constant = +"SomeThingThatIsNotAConstant"

            expect(Sidekiq::Queue).not_to receive(:new).with(any_args)
            model.sidekiq_remove_jobs(job_klasses: [my_non_constant])
          end
        end

        context "when the constant is defined" do
          it "will use it find job instances to delete" do
            my_constant = worker.name
            expect(Sidekiq::Queue)
              .to receive(:new)
              .with(worker.queue)
              .and_call_original
            model.sidekiq_remove_jobs(job_klasses: [my_constant])
          end
        end

        it "removes all related job instances from the job classes' queues" do
          Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
            worker.perform_async
            worker_two.perform_async
            same_queue_different_worker.perform_async
            unrelated_worker.perform_async
          end

          worker_queue = Sidekiq::Queue.new(worker.queue)
          worker_two_queue = Sidekiq::Queue.new(worker_two.queue)
          unrelated_queue = Sidekiq::Queue.new(unrelated_worker.queue)

          Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
            expect(worker_queue.size).to eq(2)
            expect(worker_two_queue.size).to eq(1)
            expect(unrelated_queue.size).to eq(1)
          end

          model.sidekiq_remove_jobs(job_klasses: [worker.name, worker_two.name])

          Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
            expect(worker_queue.size).to eq(1)
            expect(worker_two_queue.size).to eq(0)
            expect(worker_queue.map(&:klass)).not_to include(worker.name)
            expect(worker_queue.map(&:klass)).to include(
              same_queue_different_worker.name
            )
            expect(worker_two_queue.map(&:klass)).not_to include(worker_two.name)
            expect(unrelated_queue.size).to eq(1)
          end
        end

        context "when job instances are in the scheduled set", :allow_unrouted_sidekiq_calls do
          it "removes all related job instances from the scheduled set" do
            worker.perform_in(1.hour)
            worker_two.perform_in(1.hour)
            unrelated_worker.perform_in(1.hour)

            scheduled = Sidekiq::ScheduledSet.new

            expect(scheduled.size).to eq(3)
            expect(scheduled.map(&:klass)).to include(
              worker.name,
              worker_two.name,
              unrelated_worker.name
            )

            model.sidekiq_remove_jobs(job_klasses: [worker.name, worker_two.name])

            expect(scheduled.size).to eq(1)
            expect(scheduled.map(&:klass)).not_to include(worker.name)
            expect(scheduled.map(&:klass)).not_to include(worker_two.name)
            expect(scheduled.map(&:klass)).to include(unrelated_worker.name)
          end
        end

        context "when job instances are in the retry set", :allow_unrouted_sidekiq_calls do
          include_context "when handling retried jobs"

          it "removes all related job instances from the retry set" do
            retry_in(worker, 1.hour)
            retry_in(worker, 2.hours)
            retry_in(worker, 3.hours)
            retry_in(worker_two, 4.hours)
            retry_in(unrelated_worker, 5.hours)

            retries = Sidekiq::RetrySet.new

            expect(retries.size).to eq(5)
            expect(retries.map(&:klass)).to include(
              worker.name,
              worker_two.name,
              unrelated_worker.name
            )

            model.sidekiq_remove_jobs(job_klasses: [worker.name, worker_two.name])

            expect(retries.size).to eq(1)
            expect(retries.map(&:klass)).not_to include(worker.name)
            expect(retries.map(&:klass)).not_to include(worker_two.name)
            expect(retries.map(&:klass)).to include(unrelated_worker.name)
          end
        end

        # Imitate job deletion returning zero and then non zero.
        context "when job fails to be deleted", :allow_unrouted_sidekiq_calls do
          let(:job_double) do
            instance_double(
              "Sidekiq::JobRecord",
              klass: worker.name
            )
          end

          context "and does not work enough times in a row before max attempts" do
            it "tries the max attempts without succeeding" do
              worker.perform_async

              allow(job_double).to receive(:delete).and_return(true)

              # Scheduled set runs last so only need to stub out its values.
              allow(Sidekiq::ScheduledSet)
                .to receive(:new)
                .and_return([job_double])

              expect(model.sidekiq_remove_jobs(job_klasses: [worker.name]))
                .to eq(
                  {
                    attempts: 5,
                    success: false
                  }
                )
            end
          end

          context "and then it works enough times in a row before max attempts" do
            it "succeeds" do
              worker.perform_async

              # attempt 1: false will increment the streak once to 1
              # attempt 2: true resets it back to 0
              # attempt 3: false will increment the streak once to 1
              # attempt 4: false will increment the streak once to 2, loop breaks
              allow(job_double).to receive(:delete).and_return(false, true, false)

              worker.perform_async

              # Scheduled set runs last so only need to stub out its values.
              allow(Sidekiq::ScheduledSet)
                .to receive(:new)
                .and_return([job_double])

              expect(model.sidekiq_remove_jobs(job_klasses: [worker.name]))
                .to eq(
                  {
                    attempts: 4,
                    success: true
                  }
                )
            end
          end
        end
      end
    end

    describe "#sidekiq_queue_migrate" do
      let(:job_hash) do
        Sidekiq.dump_json({ retry: true,
                  queue: "test",
                  args: ['Something', [1]],
                  class: WorkerClass,
                  jid: 'random_jid' })
      end

      it "migrates jobs from one sidekiq queue to another", :allow_unrouted_sidekiq_calls do
        Sidekiq::Testing.disable! do
          worker.perform_async("Something", [1])
          worker.perform_async("Something", [2])

          Sidekiq.redis do |c|
            expect(c.llen("queue:test")).to eq 2
            expect(c.llen("queue:destination")).to eq 0
          end

          model.sidekiq_queue_migrate("test", to: "destination")

          Sidekiq.redis do |c|
            expect(c.llen("queue:test")).to eq 0
            expect(c.llen("queue:destination")).to eq 2
          end
        end
      end

      shared_examples 'cross instance migration' do
        it 'migrates jobs from main and shard instances to main instance' do
          Sidekiq::Testing.disable! do
            # .perform_async internally calls Sidekiq::Client.via and re-route the job to
            # Gitlab::Redis::Queues's Redis instance.
            Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
              shard_instance.sidekiq_redis.with { |c| c.lpush('queue:test', job_hash) }
              Gitlab::Redis::Queues.sidekiq_redis.with { |c| c.lpush('queue:test', job_hash) }
            end

            # 1 job in each instance's queue
            Sidekiq::Client.via(shard_instance.sidekiq_redis) do
              Sidekiq.redis do |c|
                expect(c.llen("queue:test")).to eq 1
                expect(c.llen("queue:destination")).to eq 0
              end
            end

            Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
              Sidekiq.redis do |c|
                expect(c.llen("queue:test")).to eq 1
                expect(c.llen("queue:destination")).to eq 0
              end
            end

            model.sidekiq_queue_migrate("test", to: "destination")

            # 2 job in the main instance's queue
            Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
              Sidekiq.redis do |c|
                expect(c.llen("queue:test")).to eq main_from_size
                expect(c.llen("queue:destination")).to eq main_to_size
              end
            end

            # queues in shard get emptied
            Sidekiq::Client.via(shard_instance.sidekiq_redis) do
              Sidekiq.redis do |c|
                expect(c.llen("queue:test")).to eq shard_from_size
                expect(c.llen("queue:destination")).to eq shard_to_size
              end
            end
          end
        end
      end

      shared_examples 'holds jobs in buffer until migration completes' do
        before do
          allow(Sidekiq).to receive(:load_json).and_raise(StandardError)
        end

        it 'stores migrated job in a buffer' do
          Sidekiq::Testing.disable! do
            Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
              worker.perform_async("Something", [1])
              worker.perform_async("Something", [2])

              Sidekiq.redis do |c|
                expect(c.llen("queue:test")).to eq 2
                expect(c.llen("queue:destination")).to eq 0
              end
            end

            expect { model.sidekiq_queue_migrate("test", to: "destination") }.to raise_error(StandardError)

            Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
              Sidekiq.redis do |c|
                expect(c.llen("queue:test")).to eq 1
                expect(c.llen("migration_buffer:queue:test")).to eq 1
              end
            end
          end
        end
      end

      context 'when migrating jobs across redis instances' do
        let(:shard_instance) do
          Class.new(Gitlab::Redis::Queues) do
            define_singleton_method(:store_name) do
              'shard'.camelize
            end

            define_singleton_method(:params) do
              Gitlab::Redis::Queues.params.tap { |h| h[:db] = h[:db].to_i + 1 } # set shard instance in another db
            end
          end
        end

        let(:stores) { %w[main shard] }

        before do
          Gitlab::Redis::Queues.with(&:flushdb)
          shard_instance.with(&:flushdb)

          allow(Gitlab::Redis::Queues).to receive(:instances).and_return('main' => Gitlab::Redis::Queues,
            'shard' => shard_instance) # stub Queues with extra shard instances

          allow(Gitlab::SidekiqConfig::WorkerRouter.global).to receive(:stores_with_queue).and_call_original

          # stub .store since all worker classes does not implement generated_queue_name
          allow(Gitlab::SidekiqConfig::WorkerRouter.global).to receive(:store).and_return(nil)

          skip_default_enabled_yaml_check

          # We stub using `allow(Feature)` as dynamically defined feature flag in Gitlab::SidekiqSharding::Router
          # will require a definition file when using stub_feature_flags.
          allow(Feature).to receive(:enabled?).and_call_original
          allow(Feature).to receive(:enabled?).with(:sidekiq_route_to_shard, type: :ops,
            default_enabled_if_undefined: nil).and_return(true)
        end

        context 'when there are multiple source stores and 1 destination store' do
          before do
            allow(Gitlab::SidekiqConfig::WorkerRouter.global)
              .to receive(:stores_with_queue).with('test').and_return(stores)
          end

          it_behaves_like 'cross instance migration' do
            let(:main_from_size) { 0 }
            let(:main_to_size) { 2 }

            let(:shard_from_size) { 0 }
            let(:shard_to_size) { 0 }
          end

          it_behaves_like 'holds jobs in buffer until migration completes'
        end

        context 'when there are multiple destination stores and 1 source store' do
          before do
            allow(Gitlab::SidekiqConfig::WorkerRouter.global)
              .to receive(:stores_with_queue).with('destination').and_return(stores)
          end

          it_behaves_like 'cross instance migration' do
            let(:main_from_size) { 0 }
            let(:main_to_size) { 1 }

            let(:shard_from_size) { 1 } # shard store is not accessed
            let(:shard_to_size) { 0 }
          end

          it_behaves_like 'holds jobs in buffer until migration completes'
        end

        context 'when there are multiple source and destination stores' do
          before do
            allow(Gitlab::SidekiqConfig::WorkerRouter.global)
              .to receive(:stores_with_queue).and_return(stores)

            allow(Gitlab::SidekiqConfig::WorkerRouter.global)
              .to receive(:store).and_return('main', 'shard')
          end

          it_behaves_like 'cross instance migration' do
            let(:main_from_size) { 0 }
            let(:main_to_size) { 1 }

            let(:shard_from_size) { 0 }
            let(:shard_to_size) { 1 }
          end

          it_behaves_like 'holds jobs in buffer until migration completes'
        end

        context 'when there is 1 source and 1 destination store' do
          context 'when it is the same instance', :allow_unrouted_sidekiq_calls do
            before do
              allow(Gitlab::SidekiqConfig::WorkerRouter.global)
                .to receive(:stores_with_queue).and_return(['main'])
            end

            it_behaves_like 'cross instance migration' do
              let(:main_from_size) { 0 }
              let(:main_to_size) { 1 } # migrates job within instance

              let(:shard_from_size) { 1 }
              let(:shard_to_size) { 0 }
            end
          end

          context 'when it is cross-instance' do
            before do
              allow(Gitlab::SidekiqConfig::WorkerRouter.global)
                .to receive(:stores_with_queue).with('test').and_return(['main'])
              allow(Gitlab::SidekiqConfig::WorkerRouter.global)
                .to receive(:stores_with_queue).with('destination').and_return(['shard'])
            end

            it_behaves_like 'cross instance migration' do
              let(:main_from_size) { 0 }
              let(:main_to_size) { 0 }

              let(:shard_from_size) { 1 }
              let(:shard_to_size) { 1 } # migrates job across instance
            end

            it_behaves_like 'holds jobs in buffer until migration completes'
          end

          context 'when routing is disabled', :allow_unrouted_sidekiq_calls do
            before do
              allow(Gitlab::SidekiqSharding::Router).to receive(:enabled?).and_return(false)
              allow(Gitlab::SidekiqConfig::WorkerRouter.global)
                .to receive(:stores_with_queue).with('test').and_return(['main'])
              allow(Gitlab::SidekiqConfig::WorkerRouter.global)
                .to receive(:stores_with_queue).with('destination').and_return(['shard'])
            end

            it_behaves_like 'cross instance migration' do
              let(:main_from_size) { 0 }
              let(:main_to_size) { 1 } # migrate the job only on the main instance

              let(:shard_from_size) { 1 }
              let(:shard_to_size) { 0 }
            end
          end
        end
      end
    end
  end
end
