require 'spec_helper'

describe ApplicationWorker do
  let(:worker) do
    Class.new do
      def self.name
        'Gitlab::Foo::Bar::DummyWorker'
      end

      include ApplicationWorker
    end
  end

  describe 'Sidekiq options' do
    it 'sets the queue name based on the class name' do
      expect(worker.sidekiq_options['queue']).to eq('foo_bar_dummy')
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
  end
end
