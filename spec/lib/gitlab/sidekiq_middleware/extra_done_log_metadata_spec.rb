# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::ExtraDoneLogMetadata do
  # Cannot use Class.new for this as ApplicationWorker will need the class to
  # have a name during `included do`.
  let(:worker) { AdminEmailWorker.new }

  let(:worker_without_application_worker) do
    Class.new do
    end.new
  end

  subject { described_class.new }

  let(:job) { { 'jid' => 123 } }
  let(:queue) { 'test_queue' }

  describe '#call' do
    it 'merges Application#logging_extras in to job' do
      worker.log_extra_metadata_on_done(:key1, 15)
      worker.log_extra_metadata_on_done(:key2, 16)
      expect { |b| subject.call(worker, job, queue, &b) }.to yield_control

      expect(job).to eq({ 'jid' => 123, 'extra.admin_email_worker.key1' => 15, 'extra.admin_email_worker.key2' => 16 })
    end

    it 'does not raise when the worker does not respond to #done_log_extra_metadata' do
      expect { |b| subject.call(worker_without_application_worker, job, queue, &b) }.to yield_control

      expect(job).to eq({ 'jid' => 123 })
    end
  end
end
