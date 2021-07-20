# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationWorker do
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

        worker.feature_category_not_owned!
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

  describe '.perform_async' do
    shared_examples_for 'worker utilizes load balancing capabilities' do |data_consistency|
      before do
        worker.data_consistency(data_consistency)
      end

      it 'call perform_in' do
        expect(worker).to receive(:perform_in).with(described_class::DEFAULT_DELAY_INTERVAL.seconds, 123)

        worker.perform_async(123)
      end
    end

    context 'when workers data consistency is :sticky' do
      it_behaves_like 'worker utilizes load balancing capabilities', :sticky
    end

    context 'when workers data consistency is :delayed' do
      it_behaves_like 'worker utilizes load balancing capabilities', :delayed
    end

    context 'when workers data consistency is :always' do
      before do
        worker.data_consistency(:always)
      end

      it 'does not call perform_in' do
        expect(worker).not_to receive(:perform_in)

        worker.perform_async
      end
    end
  end

  describe '.bulk_perform_async' do
    it 'enqueues jobs in bulk' do
      Sidekiq::Testing.fake! do
        worker.bulk_perform_async([['Foo', [1]], ['Foo', [2]]])

        expect(worker.jobs.count).to eq 2
        expect(worker.jobs).to all(include('enqueued_at'))
      end
    end
  end

  describe '.bulk_perform_in' do
    context 'when delay is valid' do
      it 'correctly schedules jobs' do
        Sidekiq::Testing.fake! do
          worker.bulk_perform_in(1.minute, [['Foo', [1]], ['Foo', [2]]])

          expect(worker.jobs.count).to eq 2
          expect(worker.jobs).to all(include('at'))
        end
      end
    end

    context 'when delay is invalid' do
      it 'raises an ArgumentError exception' do
        expect { worker.bulk_perform_in(-60, [['Foo']]) }
          .to raise_error(ArgumentError)
      end
    end

    context 'with batches' do
      let(:batch_delay) { 1.minute }

      it 'correctly schedules jobs' do
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

        worker.bulk_perform_in(
          1.minute,
          [['Foo', [1]], ['Foo', [2]], ['Foo', [3]], ['Foo', [4]], ['Foo', [5]]],
          batch_size: 2, batch_delay: batch_delay)

        expect(worker.jobs.count).to eq 5
        expect(worker.jobs[0]['at']).to eq(worker.jobs[1]['at'])
        expect(worker.jobs[2]['at']).to eq(worker.jobs[3]['at'])
        expect(worker.jobs[2]['at'] - worker.jobs[1]['at']).to eq(batch_delay)
        expect(worker.jobs[4]['at'] - worker.jobs[3]['at']).to eq(batch_delay)
      end

      context 'when batch_size is invalid' do
        it 'raises an ArgumentError exception' do
          expect do
            worker.bulk_perform_in(1.minute,
                                   [['Foo']],
                                   batch_size: -1, batch_delay: batch_delay)
          end.to raise_error(ArgumentError)
        end
      end
    end
  end
end
