# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::QueryLogs, feature_category: :database do
  let(:worker) { instance_double(ApplicationWorker) }
  let(:job) { { 'jid' => 'abc123', 'correlation_id' => 'cid1' } }
  let(:queue) { 'queue1' }

  describe '#call' do
    it 'exposes the job to the execution context for the duration of the block' do
      described_class.new.call(worker, job, queue) do
        expect(ActiveSupport::ExecutionContext.to_h[:job]).to eq(job)
      end

      expect(ActiveSupport::ExecutionContext.to_h[:job]).to be_nil
    end

    it 'clears the execution context when the job raises' do
      expect { described_class.new.call(worker, job, queue) { raise 'boom' } }.to raise_error('boom')

      expect(ActiveSupport::ExecutionContext.to_h[:job]).to be_nil
    end
  end
end
