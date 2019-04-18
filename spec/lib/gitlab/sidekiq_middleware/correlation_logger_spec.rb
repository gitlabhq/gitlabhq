# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SidekiqMiddleware::CorrelationLogger do
  class TestWorker
    include ApplicationWorker
  end

  before do |example|
    Sidekiq::Testing.server_middleware do |chain|
      chain.add described_class
    end
  end

  after do |example|
    Sidekiq::Testing.server_middleware do |chain|
      chain.remove described_class
    end
  end

  it 'injects into payload the correlation id' do
    expect_any_instance_of(described_class).to receive(:call).and_call_original

    expect_any_instance_of(TestWorker).to receive(:perform).with(1234) do
      expect(Labkit::Correlation::CorrelationId.current_id).to eq('new-correlation-id')
    end

    Sidekiq::Client.push(
      'queue' => 'test',
      'class' => TestWorker,
      'args' => [1234],
      'correlation_id' => 'new-correlation-id')
  end
end
