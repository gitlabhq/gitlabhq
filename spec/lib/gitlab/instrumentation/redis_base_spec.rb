# frozen_string_literal: true

require 'spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::Instrumentation::RedisBase, :request_store, feature_category: :redis do
  using RSpec::Parameterized::TableSyntax
  let(:instrumentation_class_a) do
    stub_const('InstanceA', Class.new(described_class))
  end

  let(:instrumentation_class_b) do
    stub_const('InstanceB', Class.new(described_class))
  end

  let(:instrumentation_class_c) do
    stub_const('InstanceCShardCommon', Class.new(described_class))
  end

  describe '.storage_key' do
    it 'returns the class name with underscore' do
      expect(instrumentation_class_a.storage_key).to eq('instance_a')
      expect(instrumentation_class_b.storage_key).to eq('instance_b')
    end

    it 'returns the class name without storage shard details' do
      expect(instrumentation_class_c.storage_key).to eq('instance_c')
    end
  end

  describe '.shard_key' do
    it 'returns the non-shard class name with default' do
      expect(instrumentation_class_a.shard_key).to eq(described_class::DEFAULT_SHARD_KEY)
      expect(instrumentation_class_b.shard_key).to eq(described_class::DEFAULT_SHARD_KEY)
    end

    it 'returns the shard name if present' do
      expect(instrumentation_class_c.shard_key).to eq('common')
    end
  end

  describe '.payload' do
    it 'returns values that are higher than 0' do
      allow(instrumentation_class_a).to receive(:get_request_count) { 1 }
      allow(instrumentation_class_a).to receive(:query_time) { 0.1 }
      allow(instrumentation_class_a).to receive(:read_bytes) { 0.0 }
      allow(instrumentation_class_a).to receive(:write_bytes) { 123 }

      expected_payload = {
        redis_instance_a_calls: 1,
        redis_instance_a_write_bytes: 123,
        redis_instance_a_duration_s: 0.1
      }

      expect(instrumentation_class_a.payload).to eq(expected_payload)
    end

    it 'formats keys for classes with non-default shard_key' do
      allow(instrumentation_class_c).to receive(:get_request_count) { 1 }
      allow(instrumentation_class_c).to receive(:query_time) { 0.1 }
      allow(instrumentation_class_c).to receive(:read_bytes) { 0.0 }
      allow(instrumentation_class_c).to receive(:write_bytes) { 123 }

      expected_payload = {
        redis_instance_c_common_calls: 1,
        redis_instance_c_common_write_bytes: 123,
        redis_instance_c_common_duration_s: 0.1
      }

      expect(instrumentation_class_c.payload).to eq(expected_payload)
    end
  end

  describe '.add_duration' do
    it 'does not lose precision while adding' do
      precision = 1.0 / (10**::Gitlab::InstrumentationHelper::DURATION_PRECISION)
      2.times { instrumentation_class_a.add_duration(0.4 * precision) }

      # 2 * 0.4 should be 0.8 and get rounded to 1
      expect(instrumentation_class_a.query_time).to eq(1 * precision)
    end

    context 'storage key overlapping' do
      it 'keys do not overlap across storages' do
        instrumentation_class_a.add_duration(0.4)
        instrumentation_class_b.add_duration(0.5)
        instrumentation_class_c.add_duration(0.6)

        expect(instrumentation_class_a.query_time).to eq(0.4)
        expect(instrumentation_class_b.query_time).to eq(0.5)
        expect(instrumentation_class_c.query_time).to eq(0.6)
      end
    end
  end

  describe '.increment_request_count' do
    context 'storage key overlapping' do
      it 'keys do not overlap across storages' do
        3.times { instrumentation_class_a.increment_request_count }
        2.times { instrumentation_class_b.increment_request_count }
        4.times { instrumentation_class_c.increment_request_count }

        expect(instrumentation_class_a.get_request_count).to eq(3)
        expect(instrumentation_class_b.get_request_count).to eq(2)
        expect(instrumentation_class_c.get_request_count).to eq(4)
      end
    end

    it 'increments by the given amount' do
      instrumentation_class_a.increment_request_count(2)
      instrumentation_class_a.increment_request_count(3)

      expect(instrumentation_class_a.get_request_count).to eq(5)
    end
  end

  describe '.increment_write_bytes' do
    context 'storage key overlapping' do
      it 'keys do not overlap across storages' do
        2.times do
          instrumentation_class_a.increment_write_bytes(42)
          instrumentation_class_b.increment_write_bytes(77)
          instrumentation_class_c.increment_write_bytes(100)
        end

        expect(instrumentation_class_a.write_bytes).to eq(42 * 2)
        expect(instrumentation_class_b.write_bytes).to eq(77 * 2)
        expect(instrumentation_class_c.write_bytes).to eq(100 * 2)
      end
    end
  end

  describe '.increment_cross_slot_request_count' do
    context 'storage key overlapping' do
      it 'keys do not overlap across storages' do
        3.times { instrumentation_class_a.increment_cross_slot_request_count }
        2.times { instrumentation_class_b.increment_cross_slot_request_count }
        4.times { instrumentation_class_c.increment_cross_slot_request_count }

        expect(instrumentation_class_a.get_cross_slot_request_count).to eq(3)
        expect(instrumentation_class_b.get_cross_slot_request_count).to eq(2)
        expect(instrumentation_class_c.get_cross_slot_request_count).to eq(4)
      end

      it 'increments by the given amount' do
        instrumentation_class_a.increment_cross_slot_request_count(2)
        instrumentation_class_a.increment_cross_slot_request_count(3)

        expect(instrumentation_class_a.get_cross_slot_request_count).to eq(5)
      end
    end
  end

  describe '.increment_allowed_cross_slot_request_count' do
    context 'storage key overlapping' do
      it 'keys do not overlap across storages' do
        3.times { instrumentation_class_a.increment_allowed_cross_slot_request_count }
        2.times { instrumentation_class_b.increment_allowed_cross_slot_request_count }
        4.times { instrumentation_class_c.increment_allowed_cross_slot_request_count }

        expect(instrumentation_class_a.get_allowed_cross_slot_request_count).to eq(3)
        expect(instrumentation_class_b.get_allowed_cross_slot_request_count).to eq(2)
        expect(instrumentation_class_c.get_allowed_cross_slot_request_count).to eq(4)
      end

      it 'increments by the given amount' do
        instrumentation_class_a.increment_allowed_cross_slot_request_count(2)
        instrumentation_class_a.increment_allowed_cross_slot_request_count(3)

        expect(instrumentation_class_a.get_allowed_cross_slot_request_count).to eq(5)
      end
    end
  end

  describe '.increment_read_bytes' do
    context 'storage key overlapping' do
      it 'keys do not overlap across storages' do
        2.times do
          instrumentation_class_a.increment_read_bytes(42)
          instrumentation_class_b.increment_read_bytes(77)
          instrumentation_class_c.increment_read_bytes(100)
        end

        expect(instrumentation_class_a.read_bytes).to eq(42 * 2)
        expect(instrumentation_class_b.read_bytes).to eq(77 * 2)
        expect(instrumentation_class_c.read_bytes).to eq(100 * 2)
      end
    end
  end

  describe '.add_call_details' do
    before do
      allow(Gitlab::PerformanceBar).to receive(:enabled_for_request?) { true }
    end

    context 'storage key overlapping' do
      it 'keys do not overlap across storages' do
        2.times do
          instrumentation_class_a.add_call_details(0.3, [[:set]])
          instrumentation_class_b.add_call_details(0.4, [[:set]])
          instrumentation_class_c.add_call_details(0.5, [[:set]])
        end

        expect(instrumentation_class_a.detail_store).to match(
          [
            a_hash_including(commands: [[:set]], duration: 0.3, backtrace: an_instance_of(Array)),
            a_hash_including(commands: [[:set]], duration: 0.3, backtrace: an_instance_of(Array))
          ]
        )

        expect(instrumentation_class_b.detail_store).to match(
          [
            a_hash_including(commands: [[:set]], duration: 0.4, backtrace: an_instance_of(Array)),
            a_hash_including(commands: [[:set]], duration: 0.4, backtrace: an_instance_of(Array))
          ]
        )

        expect(instrumentation_class_c.detail_store).to match(
          [
            a_hash_including(commands: [[:set]], duration: 0.5, backtrace: an_instance_of(Array)),
            a_hash_including(commands: [[:set]], duration: 0.5, backtrace: an_instance_of(Array))
          ]
        )
      end
    end
  end

  describe '.redis_cluster_validate!' do
    let(:args) { [[:mget, 'foo', 'bar']] }

    before do
      instrumentation_class_a.enable_redis_cluster_validation
    end

    context 'Rails environments' do
      where(:env, :allowed, :should_raise) do
        'production' | false | false
        'production' | true | false
        'staging' | false | false
        'staging' | true | false
        'development' | true | false
        'development' | false | true
        'test' | true | false
        'test' | false | true
      end

      with_them do
        it do
          stub_rails_env(env)

          validation = -> { instrumentation_class_a.redis_cluster_validate!(args) }
          under_test = if allowed
                         -> { Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands(&validation) }
                       else
                         validation
                       end

          if should_raise
            expect(&under_test).to raise_error(::Gitlab::Instrumentation::RedisClusterValidator::CrossSlotError)
          else
            expect(&under_test).not_to raise_error
          end
        end
      end
    end
  end

  describe '.log_exception' do
    it 'logs exception with storage details' do
      expect(::Gitlab::ErrorTracking).to receive(:log_exception)
                                           .with(
                                             an_instance_of(StandardError),
                                             storage: instrumentation_class_a.storage_key,
                                             storage_shard: described_class::DEFAULT_SHARD_KEY
                                           )

      instrumentation_class_a.log_exception(StandardError.new)
    end

    context 'when sharded instrumentation class' do
      it 'logs exception with storage details' do
        expect(::Gitlab::ErrorTracking).to receive(:log_exception)
                                             .with(
                                               an_instance_of(StandardError),
                                               storage: instrumentation_class_c.storage_key,
                                               storage_shard: 'common'
                                             )

        instrumentation_class_c.log_exception(StandardError.new)
      end
    end
  end

  describe '.instance_count_connection_exception' do
    before do
      # initialise connection_exception_counter
      instrumentation_class_a.instance_count_connection_exception(StandardError.new)
    end

    it 'counts connection exception' do
      expect(instrumentation_class_a.instance_variable_get(:@connection_exception_counter)).to receive(:increment)
        .with(
          { storage: instrumentation_class_a.storage_key,
            storage_shard: described_class::DEFAULT_SHARD_KEY,
            exception: 'Redis::ConnectionError' }
        )

      instrumentation_class_a.instance_count_connection_exception(Redis::ConnectionError.new)
    end

    context 'when sharded instrumentation class counts an exception' do
      before do
        instrumentation_class_c.instance_count_connection_exception(StandardError.new)
      end

      it 'counts connection exception' do
        expect(instrumentation_class_c.instance_variable_get(:@connection_exception_counter)).to receive(:increment)
          .with(
            { storage: instrumentation_class_c.storage_key,
              storage_shard: 'common',
              exception: 'Redis::ConnectionError' }
          )

        instrumentation_class_c.instance_count_connection_exception(Redis::ConnectionError.new)
      end
    end
  end

  describe '.instance_count_cluster_pipeline_redirection' do
    let(:indices) { [1, 2, 3] }

    before do
      # initialise intance variable
      instrumentation_class_c.instance_count_cluster_pipeline_redirection(
        RedisClient::Cluster::Pipeline::RedirectionNeeded.new
      )
    end

    it 'tracks the redirection exception' do
      expect(instrumentation_class_c.instance_variable_get(:@pipeline_redirection_histogram))
        .to receive(:observe)
          .with(
            { storage: instrumentation_class_c.storage_key, storage_shard: 'common' },
            indices.size
          )

      err = RedisClient::Cluster::Pipeline::RedirectionNeeded.new
      err.indices = indices
      instrumentation_class_c.instance_count_cluster_pipeline_redirection(err)
    end

    it 'handles missing indices' do
      expect(instrumentation_class_c.instance_variable_get(:@pipeline_redirection_histogram))
        .to receive(:observe)
          .with(
            { storage: instrumentation_class_c.storage_key, storage_shard: 'common' },
            0
          )

      err = RedisClient::Cluster::Pipeline::RedirectionNeeded.new
      instrumentation_class_c.instance_count_cluster_pipeline_redirection(err)
    end
  end
end
