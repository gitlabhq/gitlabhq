# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::SizeLimiter::Validator do
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

        described_class.new(TestSizeLimiterWorker, {}, mode: 'track')
        described_class.new(TestSizeLimiterWorker, {}, mode: 'raise')
      end
    end

    context 'when the input mode is invalid' do
      it 'defaults to track mode and logs a warning message' do
        expect(::Sidekiq.logger).to receive(:warn).with('Invalid Sidekiq size limiter mode: invalid. Fallback to track mode.')

        validator = described_class.new(TestSizeLimiterWorker, {}, mode: 'invalid')

        expect(validator.mode).to eql('track')
      end
    end

    context 'when the input mode is empty' do
      it 'defaults to track mode' do
        expect(::Sidekiq.logger).not_to receive(:warn)

        validator = described_class.new(TestSizeLimiterWorker, {})

        expect(validator.mode).to eql('track')
      end
    end

    context 'when the size input is valid' do
      it 'does not log a warning message' do
        expect(::Sidekiq.logger).not_to receive(:warn)

        described_class.new(TestSizeLimiterWorker, {}, size_limit: 300)
        described_class.new(TestSizeLimiterWorker, {}, size_limit: 0)
      end
    end

    context 'when the size input is invalid' do
      it 'defaults to 0 and logs a warning message' do
        expect(::Sidekiq.logger).to receive(:warn).with('Invalid Sidekiq size limiter limit: -1')

        described_class.new(TestSizeLimiterWorker, {}, size_limit: -1)
      end
    end

    context 'when the size input is empty' do
      it 'defaults to 0' do
        expect(::Sidekiq.logger).not_to receive(:warn)

        validator = described_class.new(TestSizeLimiterWorker, {})

        expect(validator.size_limit).to be(0)
      end
    end
  end

  shared_examples 'validate limit job payload size' do
    context 'in track mode' do
      let(:mode) { 'track' }

      context 'when size limit negative' do
        let(:size_limit) { -1 }

        it 'does not track jobs' do
          expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

          validate.call(TestSizeLimiterWorker, { a: 'a' * 300 })
        end

        it 'does not raise exception' do
          expect { validate.call(TestSizeLimiterWorker, { a: 'a' * 300 }) }.not_to raise_error
        end
      end

      context 'when size limit is 0' do
        let(:size_limit) { 0 }

        it 'does not track jobs' do
          expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

          validate.call(TestSizeLimiterWorker, { a: 'a' * 300 })
        end

        it 'does not raise exception' do
          expect { validate.call(TestSizeLimiterWorker, { a: 'a' * 300 }) }.not_to raise_error
        end
      end

      context 'when job size is bigger than size limit' do
        let(:size_limit) { 50 }

        it 'tracks job' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
            be_a(Gitlab::SidekiqMiddleware::SizeLimiter::ExceedLimitError)
          )

          validate.call(TestSizeLimiterWorker, { a: 'a' * 100 })
        end

        it 'does not raise an exception' do
          expect { validate.call(TestSizeLimiterWorker, { a: 'a' * 300 }) }.not_to raise_error
        end

        context 'when the worker has big_payload attribute' do
          before do
            worker_class.big_payload!
          end

          it 'does not track jobs' do
            expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

            validate.call(TestSizeLimiterWorker, { a: 'a' * 300 })
            validate.call('TestSizeLimiterWorker', { a: 'a' * 300 })
          end

          it 'does not raise an exception' do
            expect { validate.call(TestSizeLimiterWorker, { a: 'a' * 300 }) }.not_to raise_error
            expect { validate.call('TestSizeLimiterWorker', { a: 'a' * 300 }) }.not_to raise_error
          end
        end
      end

      context 'when job size is less than size limit' do
        let(:size_limit) { 50 }

        it 'does not track job' do
          expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

          validate.call(TestSizeLimiterWorker, { a: 'a' })
        end

        it 'does not raise an exception' do
          expect { validate.call(TestSizeLimiterWorker, { a: 'a' }) }.not_to raise_error
        end
      end
    end

    context 'in raise mode' do
      let(:mode) { 'raise' }

      context 'when size limit is negative' do
        let(:size_limit) { -1 }

        it 'does not raise exception' do
          expect { validate.call(TestSizeLimiterWorker, { a: 'a' * 300 }) }.not_to raise_error
        end
      end

      context 'when size limit is 0' do
        let(:size_limit) { 0 }

        it 'does not raise exception' do
          expect { validate.call(TestSizeLimiterWorker, { a: 'a' * 300 }) }.not_to raise_error
        end
      end

      context 'when job size is bigger than size limit' do
        let(:size_limit) { 50 }

        it 'raises an exception' do
          expect do
            validate.call(TestSizeLimiterWorker, { a: 'a' * 300 })
          end.to raise_error(
            Gitlab::SidekiqMiddleware::SizeLimiter::ExceedLimitError,
            /TestSizeLimiterWorker job exceeds payload size limit/i
          )
        end

        context 'when the worker has big_payload attribute' do
          before do
            worker_class.big_payload!
          end

          it 'does not raise an exception' do
            expect { validate.call(TestSizeLimiterWorker, { a: 'a' * 300 }) }.not_to raise_error
            expect { validate.call('TestSizeLimiterWorker', { a: 'a' * 300 }) }.not_to raise_error
          end
        end
      end

      context 'when job size is less than size limit' do
        let(:size_limit) { 50 }

        it 'does not raise an exception' do
          expect { validate.call(TestSizeLimiterWorker, { a: 'a' }) }.not_to raise_error
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
      end

      it_behaves_like 'validate limit job payload size'
    end

    context 'when creating an instance with the related ENV variables' do
      let(:validate) do
        ->(worker_clas, job) do
          validator = described_class.new(worker_class, job, mode: mode, size_limit: size_limit)
          validator.validate!
        end
      end

      before do
        stub_env('GITLAB_SIDEKIQ_SIZE_LIMITER_MODE', mode)
        stub_env('GITLAB_SIDEKIQ_SIZE_LIMITER_LIMIT_BYTES', size_limit)
      end

      it_behaves_like 'validate limit job payload size'
    end

    context 'when creating an instance with mode and size limit' do
      let(:validate) do
        ->(worker_clas, job) do
          validator = described_class.new(worker_class, job, mode: mode, size_limit: size_limit)
          validator.validate!
        end
      end

      it_behaves_like 'validate limit job payload size'
    end
  end
end
