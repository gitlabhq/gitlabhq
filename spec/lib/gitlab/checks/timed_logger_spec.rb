# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Checks::TimedLogger do
  let(:log_messages) do
    {
      foo: "Foo message..."
    }
  end

  class FooCheck
    attr_accessor :logger

    INTERNAL_TIMEOUT = 50.seconds.freeze

    def initialize(start_time, ref)
      @logger = Gitlab::Checks::TimedLogger.new(start_time: start_time, timeout: INTERNAL_TIMEOUT)
      @logger.log << "Checking ref: #{ref}"
    end

    def bar_check
      2 + 2
    end

    def grpc_check
      raise GRPC::DeadlineExceeded
    end
  end

  describe '#log_timed' do
    it 'logs message' do
      start = Time.now
      check = FooCheck.new(start, "bar")

      Timecop.freeze(start + 30.seconds) do
        check.logger.log_timed(log_messages[:foo], start) { check.bar_check }
      end

      expect(check.logger.log).to eq(["Checking ref: bar", "Foo message... (30000.0ms)"])
    end

    context 'when time limit was reached' do
      it 'cancels action' do
        start = Time.now
        check = FooCheck.new(start, "bar")

        Timecop.freeze(start + 50.seconds) do
          expect do
            check.logger.log_timed(log_messages[:foo], start) do
              check.bar_check
            end
          end.to raise_error(described_class::TimeoutError)
        end

        expect(check.logger.log).to eq(["Checking ref: bar", "Foo message... (cancelled)"])
      end

      it 'cancels action with time elapsed if work was performed' do
        start = Time.now
        check = FooCheck.new(start, "bar")

        Timecop.freeze(start + 30.seconds) do
          expect do
            check.logger.log_timed(log_messages[:foo], start) do
              check.grpc_check
            end
          end.to raise_error(described_class::TimeoutError)

          expect(check.logger.log).to eq(["Checking ref: bar", "Foo message... (cancelled after 30000.0ms)"])
        end
      end
    end
  end
end
