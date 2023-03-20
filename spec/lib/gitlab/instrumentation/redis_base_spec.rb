# frozen_string_literal: true

require 'spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::Instrumentation::RedisBase, :request_store do
  using RSpec::Parameterized::TableSyntax
  let(:instrumentation_class_a) do
    stub_const('InstanceA', Class.new(described_class))
  end

  let(:instrumentation_class_b) do
    stub_const('InstanceB', Class.new(described_class))
  end

  describe '.storage_key' do
    it 'returns the class name with underscore' do
      expect(instrumentation_class_a.storage_key).to eq('instance_a')
      expect(instrumentation_class_b.storage_key).to eq('instance_b')
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

        expect(instrumentation_class_a.query_time).to eq(0.4)
        expect(instrumentation_class_b.query_time).to eq(0.5)
      end
    end
  end

  describe '.increment_request_count' do
    context 'storage key overlapping' do
      it 'keys do not overlap across storages' do
        3.times { instrumentation_class_a.increment_request_count }
        2.times { instrumentation_class_b.increment_request_count }

        expect(instrumentation_class_a.get_request_count).to eq(3)
        expect(instrumentation_class_b.get_request_count).to eq(2)
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
        end

        expect(instrumentation_class_a.write_bytes).to eq(42 * 2)
        expect(instrumentation_class_b.write_bytes).to eq(77 * 2)
      end
    end
  end

  describe '.increment_cross_slot_request_count' do
    context 'storage key overlapping' do
      it 'keys do not overlap across storages' do
        3.times { instrumentation_class_a.increment_cross_slot_request_count }
        2.times { instrumentation_class_b.increment_cross_slot_request_count }

        expect(instrumentation_class_a.get_cross_slot_request_count).to eq(3)
        expect(instrumentation_class_b.get_cross_slot_request_count).to eq(2)
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

        expect(instrumentation_class_a.get_allowed_cross_slot_request_count).to eq(3)
        expect(instrumentation_class_b.get_allowed_cross_slot_request_count).to eq(2)
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
        end

        expect(instrumentation_class_a.read_bytes).to eq(42 * 2)
        expect(instrumentation_class_b.read_bytes).to eq(77 * 2)
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
                                             storage: instrumentation_class_a.storage_key
                                           )

      instrumentation_class_a.log_exception(StandardError.new)
    end
  end
end
