# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationWorker, feature_category: :shared do
  # We depend on the lazy-load characteristic of rspec. If the worker is loaded
  # before setting up, it's likely to go wrong. Consider this catcha:
  # before do
  #   allow(router).to receive(:route).with(worker).and_return('queue_1')
  # end
  # As worker is triggered, it includes ApplicationWorker, and the router is
  # called before it is stubbed. That makes the stubbing useless.
  let(:worker) do
    Class.new do
      def self.name
        'Gitlab::Foo::Bar::DummyWorker'
      end

      include ApplicationWorker
    end
  end

  let(:instance) { worker.new }
  let(:router) { double(:router) }

  before do
    # Set up Sidekiq.default_configuration's Thread.current[:sidekiq_redis_pool].
    # Creating a RedisConnection during spec's runtime will perform Sidekiq.info which messes with our spec expectations.
    Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls { Sidekiq.redis(&:ping) }

    allow(Feature).to receive(:enabled?).and_call_original
    allow(Feature).to receive(:enabled?).with(:route_to_main, type: :ops).and_return(true)
    allow(router).to receive(:store).and_return('main')

    allow(::Gitlab::SidekiqConfig::WorkerRouter).to receive(:global).and_return(router)
    allow(router).to receive(:route).and_return('foo_bar_dummy')
  end

  describe 'Sidekiq attributes' do
    it 'sets the queue name based on the output of the router' do
      expect(worker.sidekiq_options['queue']).to eq('foo_bar_dummy')
      expect(router).to have_received(:route).with(worker).at_least(:once)
    end

    context 'when a worker attribute is updated' do
      before do
        counter = 0
        allow(router).to receive(:route) do
          counter += 1
          "queue_#{counter}"
        end
      end

      it 'updates the queue name afterward' do
        expect(worker.sidekiq_options['queue']).to eq('queue_1')

        worker.feature_category :pages
        expect(worker.sidekiq_options['queue']).to eq('queue_2')

        worker.feature_category :not_owned
        expect(worker.sidekiq_options['queue']).to eq('queue_3')

        worker.urgency :high
        expect(worker.sidekiq_options['queue']).to eq('queue_4')

        worker.worker_has_external_dependencies!
        expect(worker.sidekiq_options['queue']).to eq('queue_5')

        worker.worker_resource_boundary :cpu
        expect(worker.sidekiq_options['queue']).to eq('queue_6')

        worker.idempotent!
        expect(worker.sidekiq_options['queue']).to eq('queue_7')

        worker.weight 3
        expect(worker.sidekiq_options['queue']).to eq('queue_8')

        worker.tags :hello
        expect(worker.sidekiq_options['queue']).to eq('queue_9')

        worker.big_payload!
        expect(worker.sidekiq_options['queue']).to eq('queue_10')

        expect(router).to have_received(:route).with(worker).at_least(10).times
      end
    end

    context 'when the worker is inherited' do
      let(:sub_worker) { Class.new(worker) }

      before do
        allow(router).to receive(:route).and_return('queue_1')
        worker # Force loading worker 1 to update its queue

        allow(router).to receive(:route).and_return('queue_2')
      end

      it 'sets the queue name for the inherited worker' do
        expect(sub_worker.sidekiq_options['queue']).to eq('queue_2')

        expect(router).to have_received(:route).with(sub_worker).at_least(:once)
      end
    end
  end

  describe '#logging_extras' do
    it 'returns extra data to be logged that was set from #log_extra_metadata_on_done' do
      instance.log_extra_metadata_on_done(:key1, "value1")
      instance.log_extra_metadata_on_done(:key2, "value2")

      expect(instance.logging_extras).to eq({ 'extra.gitlab_foo_bar_dummy_worker.key1' => "value1", 'extra.gitlab_foo_bar_dummy_worker.key2' => "value2" })
    end

    it 'returns extra data to be logged that was set from #log_hash_metadata_on_done' do
      instance.log_hash_metadata_on_done({ key1: 'value0', key2: 'value1' })

      expect(instance.logging_extras).to match_array({
        'extra.gitlab_foo_bar_dummy_worker.key1' => 'value0',
        'extra.gitlab_foo_bar_dummy_worker.key2' => 'value1'
      })
    end

    context 'when nothing is set' do
      it 'returns {}' do
        expect(instance.logging_extras).to eq({})
      end
    end
  end

  describe '#structured_payload' do
    let(:payload) { {} }

    subject(:result) { instance.structured_payload(payload) }

    it 'adds worker related payload' do
      instance.jid = 'a jid'

      expect(result).to include(
        'class' => instance.class.name,
        'job_status' => 'running',
        'queue' => worker.queue,
        'jid' => instance.jid
      )
    end

    it 'adds labkit context' do
      user = build_stubbed(:user, username: 'jane-doe')

      instance.with_context(user: user) do
        expect(result).to include('meta.user' => user.username)
      end
    end

    it 'adds custom payload converting stringified keys' do
      payload[:message] = 'some message'

      expect(result).to include('message' => payload[:message])
    end

    it 'does not override predefined context keys with custom payload' do
      payload['class'] = 'custom value'

      expect(result).to include('class' => instance.class.name)
    end
  end

  describe '.queue_namespace' do
    before do
      allow(router).to receive(:route).and_return('foo_bar_dummy', 'some_namespace:foo_bar_dummy')
    end

    it 'updates the queue name from the router again' do
      expect(worker.queue).to eq('foo_bar_dummy')

      worker.queue_namespace :some_namespace

      expect(worker.queue).to eq('some_namespace:foo_bar_dummy')
    end

    it 'updates the queue_namespace options of the worker' do
      worker.queue_namespace :some_namespace

      expect(worker.queue_namespace).to eql('some_namespace')
      expect(worker.sidekiq_options['queue_namespace']).to be(:some_namespace)
    end
  end

  describe '.queue' do
    it 'returns the queue name' do
      worker.sidekiq_options queue: :some_queue

      expect(worker.queue).to eq('some_queue')
    end
  end

  describe '.data_consistency' do
    using RSpec::Parameterized::TableSyntax

    where(:data_consistency, :sidekiq_option_retry, :expect_error) do
      :delayed  | false | true
      :delayed  | 0     | true
      :delayed  | 3     | false
      :delayed  | nil   | false
      :sticky   | false | false
      :sticky   | 0     | false
      :sticky   | 3     | false
      :sticky   | nil   | false
      :always   | false | false
      :always   | 0     | false
      :always   | 3     | false
      :always   | nil   | false
    end

    with_them do
      before do
        worker.sidekiq_options retry: sidekiq_option_retry unless sidekiq_option_retry.nil?
      end

      context "when workers data consistency is #{params['data_consistency']}" do
        it "#{params['expect_error'] ? '' : 'not to '}raise an exception" do
          if expect_error
            expect { worker.data_consistency data_consistency }
              .to raise_error("Retry support cannot be disabled if data_consistency is set to :delayed")
          else
            expect { worker.data_consistency data_consistency }
              .not_to raise_error
          end
        end
      end
    end
  end

  describe '.retry' do
    using RSpec::Parameterized::TableSyntax

    where(:data_consistency, :sidekiq_option_retry, :expect_error) do
      :delayed  | false | true
      :delayed  | 0     | true
      :delayed  | 3     | false
      :sticky   | false | false
      :sticky   | 0     | false
      :sticky   | 3     | false
      :always   | false | false
      :always   | 0     | false
      :always   | 3     | false
    end

    with_them do
      before do
        worker.data_consistency(data_consistency)
      end

      context "when retry sidekiq option is #{params['sidekiq_option_retry']}" do
        it "#{params['expect_error'] ? '' : 'not to '}raise an exception" do
          if expect_error
            expect { worker.sidekiq_options retry: sidekiq_option_retry }
              .to raise_error("Retry support cannot be disabled if data_consistency is set to :delayed")
          else
            expect { worker.sidekiq_options retry: sidekiq_option_retry }
              .not_to raise_error
          end
        end
      end
    end
  end

  context 'different kinds of push_bulk' do
    shared_context 'set safe limit beyond the number of jobs to be enqueued' do
      before do
        stub_const("#{described_class}::SAFE_PUSH_BULK_LIMIT", args.count + 1)
      end
    end

    shared_context 'set safe limit below the number of jobs to be enqueued' do
      before do
        stub_const("#{described_class}::SAFE_PUSH_BULK_LIMIT", 2)
      end
    end

    shared_examples_for 'returns job_id of all enqueued jobs' do
      let(:job_id_regex) { /[0-9a-f]{12}/ }

      it 'returns job_id of all enqueued jobs' do
        job_ids = perform_action

        expect(job_ids.count).to eq(args.count)
        expect(job_ids).to all(match(job_id_regex))
      end
    end

    shared_examples_for 'enqueues the jobs in a batched fashion, with each batch enqueing jobs as per the set safe limit' do
      it 'enqueues the jobs in a batched fashion, with each batch enqueing jobs as per the set safe limit' do
        expect(Sidekiq::Client).to(
          receive(:push_bulk).with(hash_including('args' => [['Foo', [1]], ['Foo', [2]]]))
                             .ordered
                             .and_call_original)
        expect(Sidekiq::Client).to(
          receive(:push_bulk).with(hash_including('args' => [['Foo', [3]], ['Foo', [4]]]))
                             .ordered
                             .and_call_original)
        expect(Sidekiq::Client).to(
          receive(:push_bulk).with(hash_including('args' => [['Foo', [5]]]))
                            .ordered
                            .and_call_original)

        perform_action

        expect(worker.jobs.count).to eq args.count
      end
    end

    shared_examples_for 'enqueues jobs in one go' do
      it 'enqueues jobs in one go' do
        expect(Sidekiq::Client).to(
          receive(:push_bulk).with(hash_including('args' => args)).once.and_call_original)
        expect(Sidekiq.logger).not_to receive(:info)

        perform_action

        expect(worker.jobs.count).to eq args.count
      end
    end

    shared_examples_for 'logs bulk insertions' do
      it 'logs arguments and job IDs' do
        worker.log_bulk_perform_async!

        expect(Sidekiq.logger).to(
          receive(:info).with(hash_including('class' => worker.name, 'args_list' => args)).once.and_call_original)
        expect(Sidekiq.logger).to(
          receive(:info).with(hash_including('class' => worker.name, 'jid_list' => anything)).once.and_call_original)

        perform_action
      end
    end

    before do
      stub_const(worker.name, worker)
    end

    let(:args) do
      [
        ['Foo', [1]],
        ['Foo', [2]],
        ['Foo', [3]],
        ['Foo', [4]],
        ['Foo', [5]]
      ]
    end

    describe '.bulk_perform_async' do
      shared_examples_for 'does not schedule the jobs for any specific time' do
        it 'does not schedule the jobs for any specific time' do
          perform_action

          expect(worker.jobs).to all(exclude('at'))
        end
      end

      subject(:perform_action) do
        worker.bulk_perform_async(args)
      end

      context 'push_bulk in safe limit batches' do
        context 'when the number of jobs to be enqueued does not exceed the safe limit' do
          include_context 'set safe limit beyond the number of jobs to be enqueued'

          it_behaves_like 'enqueues jobs in one go'
          it_behaves_like 'logs bulk insertions'
          it_behaves_like 'returns job_id of all enqueued jobs'
          it_behaves_like 'does not schedule the jobs for any specific time'
        end

        context 'when the number of jobs to be enqueued exceeds safe limit' do
          include_context 'set safe limit below the number of jobs to be enqueued'

          it_behaves_like 'enqueues the jobs in a batched fashion, with each batch enqueing jobs as per the set safe limit'
          it_behaves_like 'returns job_id of all enqueued jobs'
          it_behaves_like 'does not schedule the jobs for any specific time'
        end
      end
    end

    describe '.bulk_perform_in' do
      context 'without batches' do
        shared_examples_for 'schedules all the jobs at a specific time' do
          it 'schedules all the jobs at a specific time' do
            perform_action

            worker.jobs.each do |job_detail|
              expect(job_detail['at']).to be_within(3.seconds).of(expected_scheduled_at_time)
            end
          end
        end

        let(:delay) { 3.minutes }
        let(:expected_scheduled_at_time) { Time.current.to_i + delay.to_i }

        subject(:perform_action) do
          worker.bulk_perform_in(delay, args)
        end

        context 'when the scheduled time falls in the past' do
          let(:delay) { -60 }

          it 'raises an ArgumentError exception' do
            expect { perform_action }
              .to raise_error(ArgumentError)
          end
        end

        context 'push_bulk in safe limit batches' do
          context 'when the number of jobs to be enqueued does not exceed the safe limit' do
            include_context 'set safe limit beyond the number of jobs to be enqueued'

            it_behaves_like 'enqueues jobs in one go'
            it_behaves_like 'returns job_id of all enqueued jobs'
            it_behaves_like 'schedules all the jobs at a specific time'
          end

          context 'when the number of jobs to be enqueued exceeds safe limit' do
            include_context 'set safe limit below the number of jobs to be enqueued'

            it_behaves_like 'enqueues the jobs in a batched fashion, with each batch enqueing jobs as per the set safe limit'
            it_behaves_like 'returns job_id of all enqueued jobs'
            it_behaves_like 'schedules all the jobs at a specific time'
          end
        end
      end

      context 'with batches' do
        shared_examples_for 'schedules all the jobs at a specific time, per batch' do
          it 'schedules all the jobs at a specific time, per batch' do
            perform_action

            expect(worker.jobs[0]['at']).to eq(worker.jobs[1]['at'])
            expect(worker.jobs[2]['at']).to eq(worker.jobs[3]['at'])
            expect(worker.jobs[2]['at'] - worker.jobs[1]['at']).to eq(batch_delay)
            expect(worker.jobs[4]['at'] - worker.jobs[3]['at']).to eq(batch_delay)
          end
        end

        let(:delay) { 1.minute }
        let(:batch_size) { 2 }
        let(:batch_delay) { 10.minutes }

        subject(:perform_action) do
          worker.bulk_perform_in(delay, args, batch_size: batch_size, batch_delay: batch_delay)
        end

        context 'when the `batch_size` is invalid' do
          context 'when `batch_size` is 0' do
            let(:batch_size) { 0 }

            it 'raises an ArgumentError exception' do
              expect { perform_action }
                .to raise_error(ArgumentError)
            end
          end

          context 'when `batch_size` is negative' do
            let(:batch_size) { -3 }

            it 'raises an ArgumentError exception' do
              expect { perform_action }
                .to raise_error(ArgumentError)
            end
          end
        end

        context 'when the `batch_delay` is invalid' do
          context 'when `batch_delay` is 0' do
            let(:batch_delay) { 0.minutes }

            it 'raises an ArgumentError exception' do
              expect { perform_action }
                .to raise_error(ArgumentError)
            end
          end

          context 'when `batch_delay` is negative' do
            let(:batch_delay) { -3.minutes }

            it 'raises an ArgumentError exception' do
              expect { perform_action }
                .to raise_error(ArgumentError)
            end
          end
        end

        context 'push_bulk in safe limit batches' do
          context 'when the number of jobs to be enqueued does not exceed the safe limit' do
            include_context 'set safe limit beyond the number of jobs to be enqueued'

            it_behaves_like 'enqueues jobs in one go'
            it_behaves_like 'returns job_id of all enqueued jobs'
            it_behaves_like 'schedules all the jobs at a specific time, per batch'
          end

          context 'when the number of jobs to be enqueued exceeds safe limit' do
            include_context 'set safe limit below the number of jobs to be enqueued'

            it_behaves_like 'enqueues the jobs in a batched fashion, with each batch enqueing jobs as per the set safe limit'
            it_behaves_like 'returns job_id of all enqueued jobs'
            it_behaves_like 'schedules all the jobs at a specific time, per batch'
          end
        end
      end
    end
  end

  describe '.deferred' do
    around do |example|
      Sidekiq::Testing.fake!(&example)
    end

    context 'when the worker is not marked as deferred' do
      it 'all deferred-related keys are nil' do
        worker.perform_async
        expect(Sidekiq::Queues[worker.queue].first['deferred']).to eq nil
        expect(Sidekiq::Queues[worker.queue].first['deferred_by']).to eq nil
        expect(Sidekiq::Queues[worker.queue].first['deferred_count']).to eq nil
      end
    end

    context 'when the worker is marked as deferred' do
      it 'correctly sets options' do
        worker.deferred(1, :feature_flag).perform_async
        expect(Sidekiq::Queues[worker.queue].first['deferred']).to eq true
        expect(Sidekiq::Queues[worker.queue].first['deferred_by']).to eq "feature_flag"
        expect(Sidekiq::Queues[worker.queue].first['deferred_count']).to eq 1
      end

      it 'sets defaults if no arguments are passed' do
        worker.deferred.perform_async
        expect(Sidekiq::Queues[worker.queue].first['deferred']).to eq true
        expect(Sidekiq::Queues[worker.queue].first['deferred_by']).to eq nil
        expect(Sidekiq::Queues[worker.queue].first['deferred_count']).to eq 0
      end
    end
  end

  describe '.concurrency_limit_resume' do
    around do |example|
      Sidekiq::Testing.fake!(&example)
    end

    context 'when the worker is not marked as deferred' do
      it 'concurrency_limit_resume key is nil' do
        worker.perform_async
        expect(Sidekiq::Queues[worker.queue].first['concurrency_limit_resume']).to eq nil
      end
    end

    context 'when the concurrency limited worker is marked as resume' do
      let(:buffered_at) { 1 }

      it 'sets resume and buffered_at attributes' do
        worker.concurrency_limit_resume(buffered_at).perform_async
        expect(Sidekiq::Queues[worker.queue].first['concurrency_limit_resume']).to eq(true)
        expect(Sidekiq::Queues[worker.queue].first['concurrency_limit_buffered_at']).to eq(buffered_at)
      end
    end
  end

  describe '.with_status' do
    around do |example|
      Sidekiq::Testing.fake!(&example)
    end

    context 'when the worker does have status_expiration set' do
      let(:status_expiration_worker) do
        Class.new(worker) do
          sidekiq_options status_expiration: 3
        end
      end

      it 'uses status_expiration from the worker' do
        status_expiration_worker.with_status.perform_async

        expect(Sidekiq::Queues[status_expiration_worker.queue].first).to include('status_expiration' => 3)
        expect(Sidekiq::Queues[status_expiration_worker.queue].length).to eq(1)
      end

      it 'uses status_expiration from the worker without with_status' do
        status_expiration_worker.perform_async

        expect(Sidekiq::Queues[status_expiration_worker.queue].first).to include('status_expiration' => 3)
        expect(Sidekiq::Queues[status_expiration_worker.queue].length).to eq(1)
      end
    end

    context 'when the worker does not have status_expiration set' do
      it 'uses the default status_expiration' do
        worker.with_status.perform_async

        expect(Sidekiq::Queues[worker.queue].first).to include('status_expiration' => Gitlab::SidekiqStatus::DEFAULT_EXPIRATION)
        expect(Sidekiq::Queues[worker.queue].length).to eq(1)
      end

      it 'does not set status_expiration without with_status' do
        worker.perform_async

        expect(Sidekiq::Queues[worker.queue].first).not_to include('status_expiration')
        expect(Sidekiq::Queues[worker.queue].length).to eq(1)
      end
    end
  end

  describe '.rescheduled_once' do
    around do |example|
      Sidekiq::Testing.fake!(&example)
    end

    it 'sets rescheduled_once in job hash' do
      worker.rescheduled_once.perform_async

      expect(Sidekiq::Queues[worker.queue].first).to include('rescheduled_once' => true)
    end

    it 'does not set rescheduled_once key if .rescheduled_once is not called' do
      worker.perform_async

      expect(Sidekiq::Queues[worker.queue].first).not_to include('rescheduled_once' => true)
    end
  end

  describe '.with_ip_address_state' do
    around do |example|
      Sidekiq::Testing.fake!(&example)
    end

    let(:ip_address) { '1.1.1.1' }

    it 'sets IP state' do
      allow(::Gitlab::IpAddressState).to receive(:current).and_return(ip_address)

      worker.with_ip_address_state.perform_async

      expect(Sidekiq::Queues[worker.queue].first).to include('ip_address_state' => ip_address)
      expect(Sidekiq::Queues[worker.queue].length).to eq(1)
    end
  end

  context 'when using perform_async/in/at' do
    let(:shard_pool) { 'dummy_pool' }
    let(:shard_name) { 'shard_name' }

    shared_examples 'uses shard router' do
      context 'with enable_sidekiq_shard_router disabled' do
        before do
          allow(Gitlab::SidekiqSharding::Router).to receive(:enabled?).and_return(false)
        end

        it 'does not use the router' do
          expect(Sidekiq::Client).not_to receive(:via)

          operation
        end
      end

      context 'with router enabled' do
        before do
          allow(Gitlab::SidekiqSharding::Router).to receive(:enabled?).and_return(true)
        end

        it 'routes job using Sidekiq::Client.via' do
          expect(Gitlab::SidekiqSharding::Router).to receive(:get_shard_instance).and_return([shard_name, shard_pool])
          expect(Gitlab::ApplicationContext)
            .to receive(:with_context).with(sidekiq_destination_shard_redis: shard_name).and_call_original
          expect(Sidekiq::Client).to receive(:via).with(shard_pool)

          operation
        end
      end
    end

    context 'with ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper' do
      let(:worker) { ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper }

      context 'when calling perform_async with setter' do
        subject(:operation) { worker.set(testing: true).perform_async({ 'job_class' => ActionMailer::MailDeliveryJob }) }

        it_behaves_like 'uses shard router'
      end

      context 'when calling perform_async with setter without job_class' do
        subject(:operation) { worker.set(testing: true).perform_async }

        it_behaves_like 'uses shard router'
      end

      context 'when calling perform_in with setter' do
        subject(:operation) { worker.set(testing: true).perform_in(1, { 'job_class' => ActionMailer::MailDeliveryJob }) }

        it_behaves_like 'uses shard router'
      end

      context 'when calling perform_in with setter without job_class' do
        subject(:operation) { worker.set(testing: true).perform_in(1) }

        it_behaves_like 'uses shard router'
      end

      context 'when calling perform_at with setter' do
        subject(:operation) { worker.set(testing: true).perform_at(1, { 'job_class' => ActionMailer::MailDeliveryJob }) }

        it_behaves_like 'uses shard router'
      end

      context 'when calling perform_at with setter without job_class' do
        subject(:operation) { worker.set(testing: true).perform_at(1) }

        it_behaves_like 'uses shard router'
      end
    end

    context 'when calling perform_async with setter' do
      subject(:operation) { worker.set(testing: true).perform_async }

      it_behaves_like 'uses shard router'
    end

    context 'when calling perform_in with setter' do
      subject(:operation) { worker.set(testing: true).perform_in(1) }

      it_behaves_like 'uses shard router'
    end

    context 'when calling perform_at with setter' do
      subject(:operation) { worker.set(testing: true).perform_at(1) }

      it_behaves_like 'uses shard router'
    end

    context 'when calling perform_async' do
      subject(:operation) { worker.perform_async }

      it_behaves_like 'uses shard router'
    end

    context 'when calling perform_in' do
      subject(:operation) { worker.perform_in(1) }

      it_behaves_like 'uses shard router'
    end

    context 'when calling perform_at' do
      subject(:operation) { worker.perform_at(1) }

      it_behaves_like 'uses shard router'
    end
  end
end
