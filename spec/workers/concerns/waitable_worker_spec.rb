# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WaitableWorker do
  let(:worker) do
    Class.new do
      def self.name
        'Gitlab::Foo::Bar::DummyWorker'
      end

      cattr_accessor(:counter) { 0 }

      include ApplicationWorker
      prepend WaitableWorker

      # This is a workaround for a Ruby 2.3.7 bug. rspec-mocks cannot restore
      # the visibility of prepended modules. See
      # https://github.com/rspec/rspec-mocks/issues/1231 for more details.
      def self.bulk_perform_inline(args_list)
      end

      def perform(count = 0)
        self.class.counter += count
      end
    end
  end

  subject(:job) { worker.new }

  describe '.bulk_perform_and_wait' do
    context '1 job' do
      it 'runs the jobs asynchronously' do
        arguments = [[1]]

        expect(worker).to receive(:bulk_perform_async).with(arguments)

        worker.bulk_perform_and_wait(arguments)
      end

      context 'when the feature flag `always_async_project_authorizations_refresh` is turned off' do
        before do
          stub_feature_flags(always_async_project_authorizations_refresh: false)
        end

        it 'inlines the job' do
          args_list = [[1]]
          expect(worker).to receive(:bulk_perform_inline).with(args_list).and_call_original
          expect(Gitlab::AppJsonLogger).to(
            receive(:info).with(a_hash_including('message' => 'running inline',
                                                 'class' => 'Gitlab::Foo::Bar::DummyWorker',
                                                 'job_status' => 'running',
                                                 'queue' => 'foo_bar_dummy'))
                          .once)

          worker.bulk_perform_and_wait(args_list)

          expect(worker.counter).to eq(1)
        end
      end
    end

    context 'between 2 and 3 jobs' do
      it 'runs the jobs asynchronously' do
        arguments = [[1], [2], [3]]

        expect(worker).to receive(:bulk_perform_async).with(arguments)

        worker.bulk_perform_and_wait(arguments)
      end
    end

    context '>= 4 jobs' do
      it 'runs jobs using sidekiq' do
        arguments = 1.upto(5).map { |i| [i] }

        expect(worker).to receive(:bulk_perform_async).with(arguments)

        worker.bulk_perform_and_wait(arguments)
      end
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
