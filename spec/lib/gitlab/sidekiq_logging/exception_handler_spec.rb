# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SidekiqLogging::ExceptionHandler do
  describe '#call' do
    let(:job) do
      {
        "class" => "TestWorker",
        "args" => [1234, 'hello'],
        "retry" => false,
        "queue" => "cronjob:test_queue",
        "queue_namespace" => "cronjob",
        "jid" => "da883554ee4fe414012f5f42",
        "correlation_id" => 'cid'
      }
    end

    let(:exception_message) { 'An error was thrown' }
    let(:backtrace) { caller }
    let(:exception) { RuntimeError.new(exception_message) }
    let(:logger) { double }

    before do
      allow(Sidekiq).to receive(:logger).and_return(logger)
      allow(exception).to receive(:backtrace).and_return(backtrace)
    end

    subject { described_class.new.call(exception, { context: 'Test', job: job }) }

    it 'logs job data into root tree' do
      expected_data = job.merge(
        error_class: 'RuntimeError',
        error_message: exception_message,
        context: 'Test',
        error_backtrace: Gitlab::BacktraceCleaner.clean_backtrace(backtrace)
      )

      expect(logger).to receive(:warn).with(expected_data)

      subject
    end
  end
end
