# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::ResourceUsageLimit::Server, feature_category: :scalability do
  subject(:middleware) { described_class.new }

  let(:worker) { Chaos::SleepWorker.new }
  let(:job) do
    {
      "class" => "Chaos::SleepWorker",
      "queue" => "a_worker",
      "args" => %w[1],
      "created_at" => 1234567890,
      "enqueued_at" => 1234567890
    }
  end

  it 'yields block' do
    expect { |b| middleware.call(worker, job, :test, &b) }.to yield_control.once
  end

  it 'calls the Gitlab::ResourceUsageLimiter' do
    expect_next_instance_of(Gitlab::ResourceUsageLimiter) do |inst|
      expect(inst).to receive(:exceeded_limits)
    end

    middleware.call(worker, job, :test) { 'pass' }
  end

  context 'when enable_sidekiq_resource_usage_tracking is disabled' do
    before do
      stub_feature_flags(enable_sidekiq_resource_usage_tracking: false)
    end

    it 'expect no limit checks to occur' do
      expect(Gitlab::ResourceUsageLimiter).not_to receive(:new)

      middleware.call(worker, job, :test) { 'pass' }
    end
  end
end
