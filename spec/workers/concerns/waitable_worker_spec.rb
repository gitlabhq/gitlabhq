require 'spec_helper'

describe WaitableWorker do
  let(:worker) do
    Class.new do
      def self.name
        'Gitlab::Foo::Bar::DummyWorker'
      end

      class << self
        cattr_accessor(:counter) { 0 }
      end

      include ApplicationWorker
      prepend WaitableWorker

      def perform(i = 0)
        self.class.counter += i
      end
    end
  end

  subject(:job) { worker.new }

  describe '.bulk_perform_and_wait' do
    it 'schedules the jobs and waits for them to complete' do
      worker.bulk_perform_and_wait([[1], [2]])

      expect(worker.counter).to eq(3)
    end

    it 'inlines workloads <= 3 jobs' do
      args_list = [[1], [2], [3]]
      expect(worker).to receive(:bulk_perform_inline).with(args_list).and_call_original

      worker.bulk_perform_and_wait(args_list)

      expect(worker.counter).to eq(6)
    end

    it 'runs > 3 jobs using sidekiq' do
      expect(worker).to receive(:bulk_perform_async)

      worker.bulk_perform_and_wait([[1], [2], [3], [4]])
    end
  end

  describe '.bulk_perform_inline' do
    it 'runs the jobs inline' do
      expect(worker).not_to receive(:bulk_perform_async)

      worker.bulk_perform_inline([[1], [2]])

      expect(worker.counter).to eq(3)
    end

    it 'enqueues jobs if an error is raised' do
      expect(worker).to receive(:bulk_perform_async).with([['foo']])

      worker.bulk_perform_inline([[1], ['foo']])
    end
  end

  describe '#perform' do
    shared_examples 'perform' do
      it 'notifies the JobWaiter when done if the key is provided' do
        key = Gitlab::JobWaiter.new.key
        expect(Gitlab::JobWaiter).to receive(:notify).with(key, job.jid)

        job.perform(*args, key)
      end

      it 'does not notify the JobWaiter when done if no key is provided' do
        expect(Gitlab::JobWaiter).not_to receive(:notify)

        job.perform(*args)
      end
    end

    context 'when the worker takes arguments' do
      let(:args) { [1] }

      it_behaves_like 'perform'
    end

    context 'when the worker takes no arguments' do
      let(:args) { [] }

      it_behaves_like 'perform'
    end
  end
end
