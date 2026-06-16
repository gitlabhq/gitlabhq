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

  describe "#map_pipeline_trigger_type" do
    it "maps push" do
      expect(instance.map_pipeline_trigger_type("push")).to eq("push")
    end

    it "maps web to manual" do
      expect(instance.map_pipeline_trigger_type("web")).to eq("manual")
    end

    it "maps merge_request_event" do
      expect(instance.map_pipeline_trigger_type("merge_request_event")).to eq("merge_request_event")
    end

    it "maps external_pull_request_event to pull_request_event" do
      expect(instance.map_pipeline_trigger_type("external_pull_request_event")).to eq("pull_request_event")
    end

    it "returns nil for unmapped sources" do
      expect(instance.map_pipeline_trigger_type("parent_pipeline")).to be_nil
    end

    it "returns nil for nil" do
      expect(instance.map_pipeline_trigger_type(nil)).to be_nil
    end
  end

  describe "#map_pipeline_task_type" do
    it "maps build" do
      expect(instance.map_pipeline_task_type("build")).to eq("build")
    end

    it "maps test" do
      expect(instance.map_pipeline_task_type("test")).to eq("test")
    end

    it "maps deploy" do
      expect(instance.map_pipeline_task_type("deploy")).to eq("deploy")
    end

    it "returns nil for unknown stages" do
      expect(instance.map_pipeline_task_type("lint")).to be_nil
    end

    it "returns nil for nil" do
      expect(instance.map_pipeline_task_type(nil)).to be_nil
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
end
