# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CronjobQueue, feature_category: :shared do
  let(:worker) do
    Class.new do
      def self.name
        'DummyWorker'
      end

      include ApplicationWorker
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

      def perform
        AnotherWorker.perform_async('identifier')
      end
    end
  end

  let(:another_worker) do
    Class.new do
      def self.name
        'AnotherWorker'
      end

      include ApplicationWorker

      # To keep track of the context that was active for certain arguments
      cattr_accessor(:contexts) { {} }

      def perform(identifier, *args)
        self.class.contexts.merge!(identifier => Gitlab::ApplicationContext.current)
      end
    end
  end

  before do
    stub_const("DummyWorker", worker)
    stub_const("AnotherWorker", another_worker)
  end

  it 'disables retrying of failed jobs' do
    expect(worker.sidekiq_options['retry']).to eq(false)
  end

  it 'automatically clears project, user and namespace from the context', :aggregate_failures do
    worker_context = worker.get_worker_context.to_lazy_hash.transform_values { |v| v.try(:call) }

    expect(worker_context[:user]).to be_nil
    expect(worker_context[:root_namespace]).to be_nil
    expect(worker_context[:project]).to be_nil
  end

  it 'gets scheduled with caller_id set to Cronjob' do
    worker.perform_async

    job = worker.jobs.last

    expect(job).to include('meta.caller_id' => 'Cronjob')
  end

  it 'gets root_caller_id from the cronjob' do
    Sidekiq::Testing.inline! do
      worker.perform_async
    end

    expect(AnotherWorker.contexts['identifier']).to include('meta.root_caller_id' => 'Cronjob')
  end

  it 'does not set the caller_id if there was already one in the context' do
    Gitlab::ApplicationContext.with_context(caller_id: 'already set') do
      worker.perform_async
    end

    job = worker.jobs.last

    expect(job).to include('meta.caller_id' => 'already set')
  end
end
