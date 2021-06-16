# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::InstrumentationLogger do
  let(:job) { { 'jid' => 123 } }
  let(:queue) { 'test_queue' }
  let(:worker) do
    Class.new do
      def self.name
        'TestDWorker'
      end

      include ApplicationWorker

      def perform(*args)
      end
    end
  end

  subject { described_class.new }

  before do
    stub_const('TestWorker', worker)
  end

  describe '#call', :request_store do
    let(:instrumentation_values) do
      {
        cpu_s: 10,
        db_count: 0,
        db_cached_count: 0,
        db_write_count: 0,
        gitaly_calls: 0,
        redis_calls: 0
      }
    end

    before do
      allow(::Gitlab::InstrumentationHelper).to receive(:add_instrumentation_data) do |values|
        values.merge!(instrumentation_values)
      end
    end

    it 'merges all instrumentation data in the job' do
      expect { |b| subject.call(worker, job, queue, &b) }.to yield_control

      expect(job[:instrumentation]).to eq(instrumentation_values)
    end
  end
end
