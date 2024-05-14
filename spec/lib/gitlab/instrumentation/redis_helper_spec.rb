# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Instrumentation::RedisHelper, :request_store, feature_category: :scalability do
  include RedisHelpers

  let(:minimal_test_class) do
    Class.new do
      include Gitlab::Instrumentation::RedisHelper
      def initialize
        @instrumentation_class = Gitlab::Instrumentation::Redis::Cache
      end

      def check_command(commands, pipelined)
        instrument_call(commands, @instrumentation_class, pipelined) { 'empty block' }
      end

      def test_read(result)
        measure_read_size(result, @instrumentation_class)
      end

      def test_write(command)
        measure_write_size(command, @instrumentation_class)
      end

      def test_exclusion(commands)
        exclude_from_apdex?(commands)
      end
    end
  end

  before do
    stub_const("MinimalTestClass", minimal_test_class)
  end

  subject(:minimal_test_class_instance) { MinimalTestClass.new }

  describe '.instrument_call' do
    let(:pipelined) { false }
    let(:command) { [[:set, 'foo', 'bar']] }

    subject(:instrumented_command) { minimal_test_class_instance.check_command(command, pipelined) }

    it 'instruments request count' do
      expect(Gitlab::Instrumentation::Redis::Cache).to receive(:instance_count_request).with(1)
      expect(Gitlab::Instrumentation::Redis::Cache).not_to receive(:instance_count_pipelined_request)

      instrumented_command
    end

    it 'performs cluster validation' do
      expect(Gitlab::Instrumentation::Redis::Cache).to receive(:redis_cluster_validate!).once

      instrumented_command
    end

    context 'when command is not valid for Redis Cluster' do
      let(:command) { [[:mget, 'foo', 'bar']] }

      before do
        allow(Gitlab::Instrumentation::Redis::Cache).to receive(:redis_cluster_validate!).and_return(false)
      end

      it 'reports cross slot request' do
        expect(Gitlab::Instrumentation::Redis::Cache).to receive(:increment_cross_slot_request_count).once

        instrumented_command
      end
    end

    context 'when an error is raised' do
      # specific error behaviours are tested in spec/lib/gitlab/instrumentation/redis_client_middleware_spec.rb
      # this spec tests for the generic behaviour to verify that `ensure` works for any general error types
      before do
        allow(Gitlab::Instrumentation::Redis::Cache).to receive(:instance_count_request)
          .and_raise(StandardError)
      end

      it 'ensures duration is tracked' do
        allow(Gitlab::Instrumentation::Redis::Cache).to receive(:instance_observe_duration).once
        allow(Gitlab::Instrumentation::Redis::Cache).to receive(:increment_request_count).with(1).once
        allow(Gitlab::Instrumentation::Redis::Cache).to receive(:add_duration).once
        allow(Gitlab::Instrumentation::Redis::Cache).to receive(:add_call_details).with(anything, command).once

        expect { instrumented_command }.to raise_error(StandardError)
      end
    end

    context 'when a RedisClient::ConnectionError is raised' do
      before do
        allow(Gitlab::Instrumentation::Redis::Cache).to receive(:instance_count_request)
          .and_raise(RedisClient::ConnectionError)
      end

      it 'silences connection errors raised during the first attempt' do
        expect(Gitlab::Instrumentation::Redis::Cache).not_to receive(:log_exception).with(RedisClient::ConnectionError)

        expect { instrumented_command }.to raise_error(StandardError)

        expect(Thread.current[:redis_client_error_count]).to eq(1)
      end

      context 'when error is raised on the second attempt' do
        before do
          Thread.current[:redis_client_error_count] = 1
        end

        it 'instruments errors on second attempt' do
          expect(Gitlab::Instrumentation::Redis::Cache).to receive(:log_exception).with(RedisClient::ConnectionError)

          expect { instrumented_command }.to raise_error(StandardError)

          expect(Thread.current[:redis_client_error_count]).to eq(2)
        end
      end
    end

    context 'when a RedisClient::Cluster::Pipeline::RedirectionNeeded is raised' do
      before do
        allow(Gitlab::Instrumentation::Redis::Cache).to receive(:instance_count_request)
          .and_raise(RedisClient::Cluster::Pipeline::RedirectionNeeded)
      end

      it 'calls instance_count_cluster_pipeline_redirection' do
        expect(Gitlab::Instrumentation::Redis::Cache)
          .to receive(:instance_count_cluster_pipeline_redirection)
            .with(RedisClient::Cluster::Pipeline::RedirectionNeeded)

        expect(Gitlab::Instrumentation::Redis::Cache).not_to receive(:instance_count_exception)

        expect { instrumented_command }.to raise_error(RedisClient::Cluster::Pipeline::RedirectionNeeded)
      end
    end

    context 'when pipelined' do
      let(:command) { [[:get, '{user1}:bar'], [:get, '{user1}:foo']] }
      let(:pipelined) { true }

      it 'instruments pipelined request count' do
        expect(Gitlab::Instrumentation::Redis::Cache).to receive(:instance_count_pipelined_request)

        instrumented_command
      end
    end
  end

  describe '.measure_read_size' do
    it 'reads array' do
      expect(Gitlab::Instrumentation::Redis::Cache).to receive(:increment_read_bytes).with(3).exactly(3).times

      minimal_test_class_instance.test_read(%w[bar foo buz])
    end

    it 'reads Integer' do
      expect(Gitlab::Instrumentation::Redis::Cache).to receive(:increment_read_bytes).with(4)

      minimal_test_class_instance.test_read(1234)
    end

    it 'reads String' do
      expect(Gitlab::Instrumentation::Redis::Cache).to receive(:increment_read_bytes).with(3)

      minimal_test_class_instance.test_read('bar')
    end
  end

  describe '.measure_write_size' do
    it 'measures command size' do
      expect(Gitlab::Instrumentation::Redis::Cache).to receive(:increment_write_bytes).with(9)

      minimal_test_class_instance.test_write([:set, 'foo', 'bar'])
    end

    it 'accept array input' do
      expect(Gitlab::Instrumentation::Redis::Cache).to receive(:increment_write_bytes).with((9 + 12))

      minimal_test_class_instance.test_write([[:set, 'foo', 'bar'], [:lpush, 'que', 'item']])
    end
  end

  describe '.exclude_from_apdex?' do
    it 'returns false if all commands are allowed' do
      expect(minimal_test_class_instance.test_exclusion([[:set, 'foo', 'bar'], [:lpush, 'que', 'item']])).to eq(false)
    end

    it 'returns true if any commands are banned' do
      expect(minimal_test_class_instance.test_exclusion([[:brpop, 'foo', 2], [:lpush, 'que', 'item']])).to eq(true)
    end
  end
end
