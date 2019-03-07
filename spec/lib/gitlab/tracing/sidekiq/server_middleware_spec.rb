# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::Tracing::Sidekiq::ServerMiddleware do
  describe '#call' do
    let(:worker_class) { 'test_worker_class' }
    let(:job) do
      {
        'class' => "jobclass",
        'queue' => "jobqueue",
        'retry' => 0,
        'args' =>  %w{1 2 3}
      }
    end
    let(:queue) { 'test_queue' }
    let(:custom_error) { Class.new(StandardError) }
    let(:span) { OpenTracing.start_span('test', ignore_active_scope: true) }
    subject { described_class.new }

    it 'yields' do
      expect(subject).to receive(:in_tracing_span).with(
        hash_including(
          operation_name: "sidekiq:jobclass",
          tags: {
            "component" =>     "sidekiq",
            "span.kind" =>     "server",
            "sidekiq.queue" => "jobqueue",
            "sidekiq.jid" =>   nil,
            "sidekiq.retry" => "0",
            "sidekiq.args" =>  "1, 2, 3"
          }
        )
      ).and_yield(span)

      expect { |b| subject.call(worker_class, job, queue, &b) }.to yield_control
    end

    it 'propagates exceptions' do
      expect { subject.call(worker_class, job, queue) { raise custom_error } }.to raise_error(custom_error)
    end
  end
end
