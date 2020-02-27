# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::SidekiqMiddleware::DuplicateJobs::Strategies::UntilExecuting do
  let(:fake_duplicate_job) do
    instance_double(Gitlab::SidekiqMiddleware::DuplicateJobs::DuplicateJob)
  end

  subject(:strategy) { described_class.new(fake_duplicate_job) }

  describe '#schedule' do
    it 'checks for duplicates before yielding' do
      expect(fake_duplicate_job).to receive(:check!).ordered.and_return('a jid')
      expect(fake_duplicate_job).to receive(:duplicate?).ordered.and_return(false)
      expect { |b| strategy.schedule({}, &b) }.to yield_control
    end

    it 'adds the jid of the existing job to the job hash' do
      allow(fake_duplicate_job).to receive(:check!).and_return('the jid')
      job_hash = {}

      expect(fake_duplicate_job).to receive(:duplicate?).and_return(true)
      expect(fake_duplicate_job).to receive(:existing_jid).and_return('the jid')

      strategy.schedule(job_hash) {}

      expect(job_hash).to include('duplicate-of' => 'the jid')
    end
  end

  describe '#perform' do
    it 'deletes the lock before executing' do
      expect(fake_duplicate_job).to receive(:delete!).ordered
      expect { |b| strategy.perform({}, &b) }.to yield_control
    end
  end
end
