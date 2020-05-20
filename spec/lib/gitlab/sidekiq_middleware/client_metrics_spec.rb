# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SidekiqMiddleware::ClientMetrics do
  context "with worker attribution" do
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
        urgency: "low" }
    end

    shared_examples "a metrics client middleware" do
      context "with mocked prometheus" do
        let(:enqueued_jobs_metric) { double('enqueued jobs metric', increment: true) }

        before do
          allow(Gitlab::Metrics).to receive(:counter).with(described_class::ENQUEUED, anything).and_return(enqueued_jobs_metric)
        end

        describe '#call' do
          it 'yields block' do
            expect { |b| subject.call(worker_class, job, :test, double, &b) }.to yield_control.once
          end

          it 'increments enqueued jobs metric with correct labels when worker is a string of the class' do
            expect(enqueued_jobs_metric).to receive(:increment).with(labels, 1)

            subject.call(worker_class.to_s, job, :test, double) { nil }
          end

          it 'increments enqueued jobs metric with correct labels' do
            expect(enqueued_jobs_metric).to receive(:increment).with(labels, 1)

            subject.call(worker_class, job, :test, double) { nil }
          end
        end
      end
    end

    context "when workers are not attributed" do
      before do
        stub_const('TestNonAttributedWorker', Class.new)
        TestNonAttributedWorker.class_eval do
          include Sidekiq::Worker
        end
      end

      it_behaves_like "a metrics client middleware" do
        let(:worker) { TestNonAttributedWorker.new }
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
        it_behaves_like "a metrics client middleware" do
          let(:urgency) { :high }
          let(:labels) { default_labels.merge(urgency: "high") }
        end
      end

      context "no urgency" do
        it_behaves_like "a metrics client middleware" do
          let(:urgency) { :throttled }
          let(:labels) { default_labels.merge(urgency: "throttled") }
        end
      end

      context "external dependencies" do
        it_behaves_like "a metrics client middleware" do
          let(:external_dependencies) { true }
          let(:labels) { default_labels.merge(external_dependencies: "yes") }
        end
      end

      context "cpu boundary" do
        it_behaves_like "a metrics client middleware" do
          let(:resource_boundary) { :cpu }
          let(:labels) { default_labels.merge(boundary: "cpu") }
        end
      end

      context "memory boundary" do
        it_behaves_like "a metrics client middleware" do
          let(:resource_boundary) { :memory }
          let(:labels) { default_labels.merge(boundary: "memory") }
        end
      end

      context "feature category" do
        it_behaves_like "a metrics client middleware" do
          let(:feature_category) { :authentication }
          let(:labels) { default_labels.merge(feature_category: "authentication") }
        end
      end

      context "combined" do
        it_behaves_like "a metrics client middleware" do
          let(:urgency) { :high }
          let(:external_dependencies) { true }
          let(:resource_boundary) { :cpu }
          let(:feature_category) { :authentication }
          let(:labels) { default_labels.merge(urgency: "high", external_dependencies: "yes", boundary: "cpu", feature_category: "authentication") }
        end
      end
    end
  end
end
