# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::SizeLimiter::ExceedLimitError do
  let(:worker_class) do
    Class.new do
      def self.name
        "TestSizeLimiterWorker"
      end

      include ApplicationWorker

      def perform(*args); end
    end
  end

  before do
    stub_const("TestSizeLimiterWorker", worker_class)
  end

  it 'encapsulates worker info' do
    exception = described_class.new(TestSizeLimiterWorker, 500, 300)

    expect(exception.message).to eql("TestSizeLimiterWorker job exceeds payload size limit")
    expect(exception.worker_class).to eql(TestSizeLimiterWorker)
    expect(exception.size).to be(500)
    expect(exception.size_limit).to be(300)
    expect(exception.sentry_extra_data).to eql(
      worker_class: 'TestSizeLimiterWorker',
      size: 500,
      size_limit: 300
    )
  end
end
