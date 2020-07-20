# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::TimedLogger do
  let!(:timeout) { 50.seconds }
  let!(:start) { Time.now }
  let!(:ref) { "bar" }
  let!(:logger) { described_class.new(start_time: start, timeout: timeout) }
  let!(:log_messages) do
    {
      foo: "Foo message..."
    }
  end

  before do
    logger.append_message("Checking ref: #{ref}")
  end

  describe '#log_timed' do
    it 'logs message' do
      Timecop.freeze(start + 30.seconds) do
        logger.log_timed(log_messages[:foo], start) { bar_check }
      end

      expect(logger.full_message).to eq("Checking ref: bar\nFoo message... (30000.0ms)")
    end

    context 'when time limit was reached' do
      it 'cancels action' do
        Timecop.freeze(start + 50.seconds) do
          expect do
            logger.log_timed(log_messages[:foo], start) do
              bar_check
            end
          end.to raise_error(described_class::TimeoutError)
        end

        expect(logger.full_message).to eq("Checking ref: bar\nFoo message... (cancelled)")
      end

      it 'cancels action with time elapsed if work was performed' do
        Timecop.freeze(start + 30.seconds) do
          expect do
            logger.log_timed(log_messages[:foo], start) do
              grpc_check
            end
          end.to raise_error(described_class::TimeoutError)

          expect(logger.full_message).to eq("Checking ref: bar\nFoo message... (cancelled after 30000.0ms)")
        end
      end
    end
  end

  def bar_check
    2 + 2
  end

  def grpc_check
    raise GRPC::DeadlineExceeded
  end
end
