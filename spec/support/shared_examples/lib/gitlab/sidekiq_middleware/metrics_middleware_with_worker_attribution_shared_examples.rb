# frozen_string_literal: true

RSpec.shared_examples 'metrics middleware with worker attribution' do
  subject { described_class.new }

  let(:queue) { :test }
  let(:worker_class) { worker.class }
  let(:job) { {} }
  let(:default_labels) do
    { queue: queue.to_s,
      worker: worker_class.to_s,
      boundary: "",
      external_dependencies: "no",
      feature_category: "",
      urgency: "low",
      destination_shard_redis: "main" }
  end

  context "when workers are not attributed" do
    before do
      stub_const('TestNonAttributedWorker', Class.new)
      TestNonAttributedWorker.class_eval do
        include Sidekiq::Worker
      end
    end

    it_behaves_like "a metrics middleware" do
      let(:worker) { TestNonAttributedWorker.new }
      let(:labels) { default_labels.merge(urgency: "") }
    end
  end

  context "when a worker is wrapped into ActiveJob" do
    before do
      stub_const('TestWrappedWorker', Class.new)
      TestWrappedWorker.class_eval do
        include Sidekiq::Worker
      end
    end

    it_behaves_like "a metrics middleware" do
      let(:job) do
        {
          "class" => ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper,
          "wrapped" => TestWrappedWorker
        }
      end

      let(:worker) { TestWrappedWorker.new }
      let(:labels) { default_labels.merge(urgency: "") }
    end
  end

  context "when workers are attributed" do
    def create_attributed_worker_class(urgency, external_dependencies, resource_boundary, category)
      klass = Class.new do
        include Sidekiq::Worker
        include WorkerAttributes

        urgency urgency if urgency
        worker_has_external_dependencies! if external_dependencies
        worker_resource_boundary resource_boundary unless resource_boundary == :unknown
        feature_category category unless category.nil?
      end
      stub_const("TestAttributedWorker", klass)
    end

    let(:urgency) { nil }
    let(:external_dependencies) { false }
    let(:resource_boundary) { :unknown }
    let(:feature_category) { nil }
    let(:worker_class) { create_attributed_worker_class(urgency, external_dependencies, resource_boundary, feature_category) }
    let(:worker) { worker_class.new }

    context "high urgency" do
      it_behaves_like "a metrics middleware" do
        let(:urgency) { :high }
        let(:labels) { default_labels.merge(urgency: "high") }
      end
    end

    context "no urgency" do
      it_behaves_like "a metrics middleware" do
        let(:urgency) { :throttled }
        let(:labels) { default_labels.merge(urgency: "throttled") }
      end
    end

    context "external dependencies" do
      it_behaves_like "a metrics middleware" do
        let(:external_dependencies) { true }
        let(:labels) { default_labels.merge(external_dependencies: "yes") }
      end
    end

    context "cpu boundary" do
      it_behaves_like "a metrics middleware" do
        let(:resource_boundary) { :cpu }
        let(:labels) { default_labels.merge(boundary: "cpu") }
      end
    end

    context "memory boundary" do
      it_behaves_like "a metrics middleware" do
        let(:resource_boundary) { :memory }
        let(:labels) { default_labels.merge(boundary: "memory") }
      end
    end

    context "feature category" do
      it_behaves_like "a metrics middleware" do
        let(:feature_category) { :authentication }
        let(:labels) { default_labels.merge(feature_category: "authentication") }
      end
    end

    context "combined" do
      it_behaves_like "a metrics middleware" do
        let(:urgency) { :high }
        let(:external_dependencies) { true }
        let(:resource_boundary) { :cpu }
        let(:feature_category) { :authentication }
        let(:labels) do
          default_labels.merge(
            urgency: "high",
            external_dependencies: "yes",
            boundary: "cpu",
            feature_category: "authentication")
        end
      end
    end
  end
end
