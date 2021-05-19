# frozen_string_literal: true

require 'spec_helper'

# rubocop: disable RSpec/MultipleMemoizedHelpers
RSpec.describe Gitlab::SidekiqMiddleware::SizeLimiter::Server, :clean_gitlab_redis_queues do
  subject(:middleware) { described_class.new }

  let(:worker) { Class.new }
  let(:job) do
    {
      "class" => "ARandomWorker",
      "queue" => "a_worker",
      "args" => %w[Hello World],
      "created_at" => 1234567890,
      "enqueued_at" => 1234567890
    }
  end

  before do
    allow(::Gitlab::SidekiqMiddleware::SizeLimiter::Compressor).to receive(:compress)
  end

  it 'yields block' do
    expect { |b| subject.call(worker, job, :test, &b) }.to yield_control.once
  end

  it 'calls the Compressor' do
    expect(::Gitlab::SidekiqMiddleware::SizeLimiter::Compressor).to receive(:decompress).with(job)

    subject.call(worker, job, :test) {}
  end
end
