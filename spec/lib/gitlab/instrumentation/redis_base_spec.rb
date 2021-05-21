# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Instrumentation::RedisBase, :request_store do
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
          instrumentation_class_a.add_call_details(0.3, [:set])
          instrumentation_class_b.add_call_details(0.4, [:set])
        end

        expect(instrumentation_class_a.detail_store).to match(
          [
            a_hash_including(cmd: :set, duration: 0.3, backtrace: an_instance_of(Array)),
            a_hash_including(cmd: :set, duration: 0.3, backtrace: an_instance_of(Array))
          ]
        )

        expect(instrumentation_class_b.detail_store).to match(
          [
            a_hash_including(cmd: :set, duration: 0.4, backtrace: an_instance_of(Array)),
            a_hash_including(cmd: :set, duration: 0.4, backtrace: an_instance_of(Array))
          ]
        )
      end
    end
  end
end
