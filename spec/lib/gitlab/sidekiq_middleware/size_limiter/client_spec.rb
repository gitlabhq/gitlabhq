# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::SizeLimiter::Client, :clean_gitlab_redis_queues do
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

  describe '#call' do
    context 'when the validator rejects the job' do
      before do
        allow(Gitlab::SidekiqMiddleware::SizeLimiter::Validator).to receive(:validate!).and_raise(
          Gitlab::SidekiqMiddleware::SizeLimiter::ExceedLimitError.new(
            TestSizeLimiterWorker, 500, 300
          )
        )
      end

      it 'raises an exception when scheduling job with #perform_at' do
        expect do
          TestSizeLimiterWorker.perform_at(30.seconds.from_now, 1, 2, 3)
        end.to raise_error Gitlab::SidekiqMiddleware::SizeLimiter::ExceedLimitError
      end

      it 'raises an exception when scheduling job with #perform_async' do
        expect do
          TestSizeLimiterWorker.perform_async(1, 2, 3)
        end.to raise_error Gitlab::SidekiqMiddleware::SizeLimiter::ExceedLimitError
      end

      it 'raises an exception when scheduling job with #perform_in' do
        expect do
          TestSizeLimiterWorker.perform_in(3.seconds, 1, 2, 3)
        end.to raise_error Gitlab::SidekiqMiddleware::SizeLimiter::ExceedLimitError
      end
    end

    context 'when the validator validates the job suscessfully' do
      before do
        # Do nothing
        allow(Gitlab::SidekiqMiddleware::SizeLimiter::Client).to receive(:validate!)
      end

      it 'raises an exception when scheduling job with #perform_at' do
        expect do
          TestSizeLimiterWorker.perform_at(30.seconds.from_now, 1, 2, 3)
        end.not_to raise_error

        expect(TestSizeLimiterWorker.jobs).to contain_exactly(
          a_hash_including(
            "class" => "TestSizeLimiterWorker",
            "args" => [1, 2, 3],
            "at" => be_a(Float)
          )
        )
      end

      it 'raises an exception when scheduling job with #perform_async' do
        expect do
          TestSizeLimiterWorker.perform_async(1, 2, 3)
        end.not_to raise_error

        expect(TestSizeLimiterWorker.jobs).to contain_exactly(
          a_hash_including(
            "class" => "TestSizeLimiterWorker",
            "args" => [1, 2, 3]
          )
        )
      end

      it 'raises an exception when scheduling job with #perform_in' do
        expect do
          TestSizeLimiterWorker.perform_in(3.seconds, 1, 2, 3)
        end.not_to raise_error

        expect(TestSizeLimiterWorker.jobs).to contain_exactly(
          a_hash_including(
            "class" => "TestSizeLimiterWorker",
            "args" => [1, 2, 3],
            "at" => be_a(Float)
          )
        )
      end
    end
  end
end
