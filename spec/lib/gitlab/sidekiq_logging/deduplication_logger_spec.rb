# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqLogging::DeduplicationLogger do
  describe '#log_deduplication' do
    let(:job) do
      {
        'class' => 'TestWorker',
        'args' => [1234, 'hello', { 'key' => 'value' }],
        'jid' => 'da883554ee4fe414012f5f42',
        'correlation_id' => 'cid',
        'duplicate-of' => 'other_jid'
      }
    end

    it 'logs a deduplication message to the sidekiq logger' do
      expected_payload = {
        'job_status' => 'deduplicated',
        'message' => "#{job['class']} JID-#{job['jid']}: deduplicated: a fancy strategy",
        'deduplication.type' => 'a fancy strategy',
        'deduplication.options.foo' => :bar
      }
      expect(Sidekiq.logger).to receive(:info).with(a_hash_including(expected_payload)).and_call_original

      described_class.instance.deduplicated_log(job, "a fancy strategy", { foo: :bar })
    end

    it "does not modify the job" do
      expect { described_class.instance.deduplicated_log(job, "a fancy strategy") }
        .not_to change { job }
    end
  end

  describe '#rescheduled_log' do
    let(:job) do
      {
        'class' => 'TestWorker',
        'args' => [1234, 'hello', { 'key' => 'value' }],
        'jid' => 'da883554ee4fe414012f5f42',
        'correlation_id' => 'cid'
      }
    end

    it 'logs a rescheduled message to the sidekiq logger' do
      expected_payload = {
        'job_status' => 'rescheduled',
        'message' => "#{job['class']} JID-#{job['jid']}: rescheduled"
      }
      expect(Sidekiq.logger).to receive(:info).with(a_hash_including(expected_payload)).and_call_original

      described_class.instance.rescheduled_log(job)
    end

    it 'does not modify the job' do
      expect { described_class.instance.rescheduled_log(job) }
        .not_to change { job }
    end
  end
end
