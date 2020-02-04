# frozen_string_literal: true

require 'spec_helper'

describe CronjobQueue do
  let(:worker) do
    Class.new do
      def self.name
        'DummyWorker'
      end

      include ApplicationWorker
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext
    end
  end

  it 'sets the queue name of a worker' do
    expect(worker.sidekiq_options['queue'].to_s).to eq('cronjob:dummy')
  end

  it 'disables retrying of failed jobs' do
    expect(worker.sidekiq_options['retry']).to eq(false)
  end

  it 'automatically clears project, user and namespace from the context', :aggregate_failues do
    worker_context = worker.get_worker_context.to_lazy_hash.transform_values(&:call)

    expect(worker_context[:user]).to be_nil
    expect(worker_context[:root_namespace]).to be_nil
    expect(worker_context[:project]).to be_nil
  end
end
