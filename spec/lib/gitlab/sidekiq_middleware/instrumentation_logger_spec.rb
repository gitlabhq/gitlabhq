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

  describe '.keys' do
    it 'returns all available payload keys' do
      expected_keys = [
        :cpu_s,
        :gitaly_calls,
        :gitaly_duration_s,
        :rugged_calls,
        :rugged_duration_s,
        :elasticsearch_calls,
        :elasticsearch_duration_s,
        :elasticsearch_timed_out_count,
        :mem_objects,
        :mem_bytes,
        :mem_mallocs,
        :redis_calls,
        :redis_duration_s,
        :redis_read_bytes,
        :redis_write_bytes,
        :redis_action_cable_calls,
        :redis_action_cable_duration_s,
        :redis_action_cable_read_bytes,
        :redis_action_cable_write_bytes,
        :redis_cache_calls,
        :redis_cache_duration_s,
        :redis_cache_read_bytes,
        :redis_cache_write_bytes,
        :redis_queues_calls,
        :redis_queues_duration_s,
        :redis_queues_read_bytes,
        :redis_queues_write_bytes,
        :redis_shared_state_calls,
        :redis_shared_state_duration_s,
        :redis_shared_state_read_bytes,
        :redis_shared_state_write_bytes,
        :db_count,
        :db_write_count,
        :db_cached_count,
        :external_http_count,
        :external_http_duration_s,
        :rack_attack_redis_count,
        :rack_attack_redis_duration_s
      ]

      expect(described_class.keys).to include(*expected_keys)
    end
  end

  describe '#call', :request_store do
    let(:instrumentation_values) do
      {
        cpu_s: 10,
        unknown_attribute: 123,
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

    it 'merges correct instrumentation data in the job' do
      expect { |b| subject.call(worker, job, queue, &b) }.to yield_control

      expected_values = instrumentation_values.except(:unknown_attribute)

      expect(job[:instrumentation]).to eq(expected_values)
    end
  end
end
