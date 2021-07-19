# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::SizeLimiter::Validator do
  let(:base_payload) do
    {
      "class" => "ARandomWorker",
      "queue" => "a_worker",
      "retry" => true,
      "jid" => "d774900367dc8b2962b2479c",
      "created_at" => 1234567890,
      "enqueued_at" => 1234567890
    }
  end

  def job_payload(args = {})
    base_payload.merge('args' => args)
  end

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

  describe '#initialize' do
    context 'when the input mode is valid' do
      it 'does not log a warning message' do
        expect(::Sidekiq.logger).not_to receive(:warn)

        described_class.new(TestSizeLimiterWorker, job_payload, mode: 'track')
        described_class.new(TestSizeLimiterWorker, job_payload, mode: 'compress')
      end
    end

    context 'when the input mode is invalid' do
      it 'defaults to track mode and logs a warning message' do
        expect(::Sidekiq.logger).to receive(:warn).with('Invalid Sidekiq size limiter mode: invalid. Fallback to track mode.')

        validator = described_class.new(TestSizeLimiterWorker, job_payload, mode: 'invalid')

        expect(validator.mode).to eql('track')
      end
    end

    context 'when the input mode is empty' do
      it 'defaults to track mode' do
        expect(::Sidekiq.logger).not_to receive(:warn)

        validator = described_class.new(TestSizeLimiterWorker, job_payload)

        expect(validator.mode).to eql('track')
      end
    end

    context 'when the size input is valid' do
      it 'does not log a warning message' do
        expect(::Sidekiq.logger).not_to receive(:warn)

        described_class.new(TestSizeLimiterWorker, job_payload, size_limit: 300)
        described_class.new(TestSizeLimiterWorker, job_payload, size_limit: 0)
      end
    end

    context 'when the size input is invalid' do
      it 'defaults to 0 and logs a warning message' do
        expect(::Sidekiq.logger).to receive(:warn).with('Invalid Sidekiq size limiter limit: -1')

        described_class.new(TestSizeLimiterWorker, job_payload, size_limit: -1)
      end
    end

    context 'when the size input is empty' do
      it 'defaults to 0' do
        expect(::Sidekiq.logger).not_to receive(:warn)

        validator = described_class.new(TestSizeLimiterWorker, job_payload)

        expect(validator.size_limit).to be(0)
      end
    end

    context 'when the compression threshold is valid' do
      it 'does not log a warning message' do
        expect(::Sidekiq.logger).not_to receive(:warn)

        described_class.new(TestSizeLimiterWorker, job_payload, compression_threshold: 300)
        described_class.new(TestSizeLimiterWorker, job_payload, compression_threshold: 1)
      end
    end

    context 'when the compression threshold is negative' do
      it 'logs a warning message' do
        expect(::Sidekiq.logger).to receive(:warn).with('Invalid Sidekiq size limiter compression threshold: -1')

        described_class.new(TestSizeLimiterWorker, job_payload, compression_threshold: -1)
      end

      it 'falls back to the default' do
        validator = described_class.new(TestSizeLimiterWorker, job_payload, compression_threshold: -1)

        expect(validator.compression_threshold).to be(100_000)
      end
    end

    context 'when the compression threshold is zero' do
      it 'logs a warning message' do
        expect(::Sidekiq.logger).to receive(:warn).with('Invalid Sidekiq size limiter compression threshold: 0')

        described_class.new(TestSizeLimiterWorker, job_payload, compression_threshold: 0)
      end

      it 'falls back to the default' do
        validator = described_class.new(TestSizeLimiterWorker, job_payload, compression_threshold: 0)

        expect(validator.compression_threshold).to be(100_000)
      end
    end

    context 'when the compression threshold is empty' do
      it 'defaults to 100_000' do
        expect(::Sidekiq.logger).not_to receive(:warn)

        validator = described_class.new(TestSizeLimiterWorker, job_payload)

        expect(validator.compression_threshold).to be(100_000)
      end
    end
  end

  shared_examples 'validate limit job payload size' do
    context 'in track mode' do
      let(:compression_threshold) { nil }
      let(:mode) { 'track' }

      context 'when size limit negative' do
        let(:size_limit) { -1 }

        it 'does not track jobs' do
          expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

          validate.call(TestSizeLimiterWorker, job_payload(a: 'a' * 300))
        end

        it 'does not raise exception' do
          expect { validate.call(TestSizeLimiterWorker, job_payload(a: 'a' * 300)) }.not_to raise_error
        end
      end

      context 'when size limit is 0' do
        let(:size_limit) { 0 }

        it 'does not track jobs' do
          expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

          validate.call(TestSizeLimiterWorker, job_payload(a: 'a' * 300))
        end

        it 'does not raise exception' do
          expect do
            validate.call(TestSizeLimiterWorker, job_payload(a: 'a' * 300))
          end.not_to raise_error
        end
      end

      context 'when job size is bigger than size limit' do
        let(:size_limit) { 50 }

        it 'tracks job' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
            be_a(Gitlab::SidekiqMiddleware::SizeLimiter::ExceedLimitError)
          )

          validate.call(TestSizeLimiterWorker, job_payload(a: 'a' * 100))
        end

        it 'does not raise an exception' do
          expect do
            validate.call(TestSizeLimiterWorker, job_payload(a: 'a' * 300))
          end.not_to raise_error
        end

        context 'when the worker has big_payload attribute' do
          before do
            worker_class.big_payload!
          end

          it 'does not track jobs' do
            expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

            validate.call(TestSizeLimiterWorker, job_payload(a: 'a' * 300))
            validate.call('TestSizeLimiterWorker', job_payload(a: 'a' * 300))
          end

          it 'does not raise an exception' do
            expect do
              validate.call(TestSizeLimiterWorker, job_payload(a: 'a' * 300))
            end.not_to raise_error
            expect do
              validate.call('TestSizeLimiterWorker', job_payload(a: 'a' * 300))
            end.not_to raise_error
          end
        end
      end

      context 'when job size is less than size limit' do
        let(:size_limit) { 50 }

        it 'does not track job' do
          expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

          validate.call(TestSizeLimiterWorker, job_payload(a: 'a'))
        end

        it 'does not raise an exception' do
          expect { validate.call(TestSizeLimiterWorker, job_payload(a: 'a')) }.not_to raise_error
        end
      end
    end

    context 'in compress mode' do
      let(:size_limit) { 50 }
      let(:compression_threshold) { 30 }
      let(:mode) { 'compress' }

      context 'when job size is less than compression threshold' do
        let(:job) { job_payload(a: 'a' * 10) }

        it 'does not raise an exception' do
          expect(::Gitlab::SidekiqMiddleware::SizeLimiter::Compressor).not_to receive(:compress)
          expect { validate.call(TestSizeLimiterWorker, job_payload(a: 'a')) }.not_to raise_error
        end
      end

      context 'when job size is bigger than compression threshold and less than size limit after compressed' do
        let(:args) { { a: 'a' * 300 } }
        let(:job) { job_payload(args) }

        it 'does not raise an exception' do
          expect(::Gitlab::SidekiqMiddleware::SizeLimiter::Compressor).to receive(:compress).with(
            job, Sidekiq.dump_json(args)
          ).and_return('a' * 40)

          expect do
            validate.call(TestSizeLimiterWorker, job)
          end.not_to raise_error
        end
      end

      context 'when the job was already compressed' do
        let(:job) do
          job_payload({ a: 'a' * 10 })
            .merge(Gitlab::SidekiqMiddleware::SizeLimiter::Compressor::COMPRESSED_KEY => true)
        end

        it 'does not compress the arguments again' do
          expect(Gitlab::SidekiqMiddleware::SizeLimiter::Compressor).not_to receive(:compress)

          expect { validate.call(TestSizeLimiterWorker, job) }.not_to raise_error
        end
      end

      context 'when job size is bigger than compression threshold and bigger than size limit after compressed' do
        let(:args) { { a: 'a' * 3000 } }
        let(:job) { job_payload(args) }

        it 'does not raise an exception' do
          expect(::Gitlab::SidekiqMiddleware::SizeLimiter::Compressor).to receive(:compress).with(
            job, Sidekiq.dump_json(args)
          ).and_return('a' * 60)

          expect do
            validate.call(TestSizeLimiterWorker, job)
          end.to raise_error(Gitlab::SidekiqMiddleware::SizeLimiter::ExceedLimitError)
        end
      end
    end
  end

  describe '#validate!' do
    context 'when calling SizeLimiter.validate!' do
      let(:validate) { ->(worker_clas, job) { described_class.validate!(worker_class, job) } }

      before do
        stub_env('GITLAB_SIDEKIQ_SIZE_LIMITER_MODE', mode)
        stub_env('GITLAB_SIDEKIQ_SIZE_LIMITER_LIMIT_BYTES', size_limit)
        stub_env('GITLAB_SIDEKIQ_SIZE_LIMITER_COMPRESSION_THRESHOLD_BYTES', compression_threshold)
      end

      it_behaves_like 'validate limit job payload size'
    end

    context 'when creating an instance with the related ENV variables' do
      let(:validate) do
        ->(worker_clas, job) do
          described_class.new(worker_class, job).validate!
        end
      end

      before do
        stub_env('GITLAB_SIDEKIQ_SIZE_LIMITER_MODE', mode)
        stub_env('GITLAB_SIDEKIQ_SIZE_LIMITER_LIMIT_BYTES', size_limit)
        stub_env('GITLAB_SIDEKIQ_SIZE_LIMITER_COMPRESSION_THRESHOLD_BYTES', compression_threshold)
      end

      it_behaves_like 'validate limit job payload size'
    end

    context 'when creating an instance with mode and size limit' do
      let(:validate) do
        ->(worker_clas, job) do
          validator = described_class.new(
            worker_class, job,
            mode: mode, size_limit: size_limit, compression_threshold: compression_threshold
          )
          validator.validate!
        end
      end

      it_behaves_like 'validate limit job payload size'
    end
  end
end
