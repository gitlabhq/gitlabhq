# frozen_string_literal: true

require "fast_spec_helper"

RSpec.describe Gitlab::Observability::CicdSemconv, feature_category: :observability do
  let(:test_class) { Class.new { include Gitlab::Observability::CicdSemconv } }
  let(:instance) { test_class.new }

  describe "#map_pipeline_result" do
    it "maps success" do
      expect(instance.map_pipeline_result("success")).to eq("success")
    end

    it "maps failed to failure" do
      expect(instance.map_pipeline_result("failed")).to eq("failure")
    end

    it "maps canceled to cancellation" do
      expect(instance.map_pipeline_result("canceled")).to eq("cancellation")
    end

    it "maps skipped to skip" do
      expect(instance.map_pipeline_result("skipped")).to eq("skip")
    end

    it "returns nil for running" do
      expect(instance.map_pipeline_result("running")).to be_nil
    end

    it "returns nil for nil" do
      expect(instance.map_pipeline_result(nil)).to be_nil
    end
  end

  describe "#map_pipeline_run_state" do
    it "maps pending" do
      expect(instance.map_pipeline_run_state("pending")).to eq("pending")
    end

    it "maps waiting_for_resource to pending" do
      expect(instance.map_pipeline_run_state("waiting_for_resource")).to eq("pending")
    end

    it "maps running to executing" do
      expect(instance.map_pipeline_run_state("running")).to eq("executing")
    end

    it "returns nil for success" do
      expect(instance.map_pipeline_run_state("success")).to be_nil
    end

    it "returns nil for nil" do
      expect(instance.map_pipeline_run_state(nil)).to be_nil
    end
  end

  describe "#map_worker_state" do
    it "returns available when active is true" do
      expect(instance.map_worker_state(true)).to eq("available")
    end

    it "returns offline when active is false" do
      expect(instance.map_worker_state(false)).to eq("offline")
    end

    it "returns offline when active is nil" do
      expect(instance.map_worker_state(nil)).to eq("offline")
    end
  end

  describe "#compact_attributes" do
    it "removes nil entries" do
      attrs = [
        { key: 'keep', value: { stringValue: 'value' } },
        nil,
        { key: 'also_keep', value: { intValue: 1 } }
      ]

      result = instance.compact_attributes(attrs)

      expect(result).to eq([
        { key: 'keep', value: { stringValue: 'value' } },
        { key: 'also_keep', value: { intValue: 1 } }
      ])
    end

    it "removes attributes with blank string values" do
      attrs = [
        { key: 'present', value: { stringValue: 'hello' } },
        { key: 'empty', value: { stringValue: '' } },
        { key: 'nil_string', value: { stringValue: nil } }
      ]

      result = instance.compact_attributes(attrs)

      expect(result).to eq([
        { key: 'present', value: { stringValue: 'hello' } }
      ])
    end

    it "preserves non-string value types regardless of value" do
      attrs = [
        { key: 'zero_int', value: { intValue: 0 } },
        { key: 'false_bool', value: { boolValue: false } }
      ]

      result = instance.compact_attributes(attrs)

      expect(result).to eq(attrs)
    end
  end
end
