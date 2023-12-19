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
    it 'instruments request count' do
      expect(Gitlab::Instrumentation::Redis::Cache).to receive(:instance_count_request).with(1)
      expect(Gitlab::Instrumentation::Redis::Cache).not_to receive(:instance_count_pipelined_request)

      minimal_test_class_instance.check_command([[:set, 'foo', 'bar']], false)
    end

    it 'performs cluster validation' do
      expect(Gitlab::Instrumentation::Redis::Cache).to receive(:redis_cluster_validate!).once

      minimal_test_class_instance.check_command([[:set, 'foo', 'bar']], false)
    end

    context 'when command is not valid for Redis Cluster' do
      before do
        allow(Gitlab::Instrumentation::Redis::Cache).to receive(:redis_cluster_validate!).and_return(false)
      end

      it 'reports cross slot request' do
        expect(Gitlab::Instrumentation::Redis::Cache).to receive(:increment_cross_slot_request_count).once

        minimal_test_class_instance.check_command([[:mget, 'foo', 'bar']], false)
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
        commands = [[:set, 'foo', 'bar']]
        allow(Gitlab::Instrumentation::Redis::Cache).to receive(:instance_observe_duration).once
        allow(Gitlab::Instrumentation::Redis::Cache).to receive(:increment_request_count).with(1).once
        allow(Gitlab::Instrumentation::Redis::Cache).to receive(:add_duration).once
        allow(Gitlab::Instrumentation::Redis::Cache).to receive(:add_call_details).with(anything, commands).once

        expect { minimal_test_class_instance.check_command(commands, false) }.to raise_error(StandardError)
      end
    end

    context 'when pipelined' do
      it 'instruments pipelined request count' do
        expect(Gitlab::Instrumentation::Redis::Cache).to receive(:instance_count_pipelined_request)

        minimal_test_class_instance.check_command([[:get, '{user1}:bar'], [:get, '{user1}:foo']], true)
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
