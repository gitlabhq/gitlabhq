# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationWorker do
  let_it_be(:worker) do
    Class.new do
      def self.name
        'Gitlab::Foo::Bar::DummyWorker'
      end

      include ApplicationWorker
    end
  end

  let(:instance) { worker.new }

  describe 'Sidekiq options' do
    it 'sets the queue name based on the class name' do
      expect(worker.sidekiq_options['queue']).to eq('foo_bar_dummy')
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
    it 'sets the queue name based on the class name' do
      worker.queue_namespace :some_namespace

      expect(worker.queue).to eq('some_namespace:foo_bar_dummy')
    end
  end

  describe '.queue' do
    it 'returns the queue name' do
      worker.sidekiq_options queue: :some_queue

      expect(worker.queue).to eq('some_queue')
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
