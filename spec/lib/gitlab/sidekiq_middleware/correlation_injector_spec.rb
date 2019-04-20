# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SidekiqMiddleware::CorrelationInjector do
  class TestWorker
    include ApplicationWorker
  end

  before do |example|
    Sidekiq.client_middleware do |chain|
      chain.add described_class
    end
  end

  after do |example|
    Sidekiq.client_middleware do |chain|
      chain.remove described_class
    end

    Sidekiq::Queues.clear_all
  end

  around do |example|
    Sidekiq::Testing.fake! do
      example.run
    end
  end

  it 'injects into payload the correlation id' do
    expect_any_instance_of(described_class).to receive(:call).and_call_original

    Labkit::Correlation::CorrelationId.use_id('new-correlation-id') do
      TestWorker.perform_async(1234)
    end

    expected_job_params = {
      "class" => "TestWorker",
      "args" => [1234],
      "correlation_id" => "new-correlation-id"
    }

    expect(Sidekiq::Queues.jobs_by_worker).to a_hash_including(
      "TestWorker" => a_collection_containing_exactly(
        a_hash_including(expected_job_params)))
  end
end
