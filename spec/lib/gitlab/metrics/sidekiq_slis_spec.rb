# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::SidekiqSlis, feature_category: :error_budgets do
  using RSpec::Parameterized::TableSyntax
  let(:labels) do
    [
      {
        worker: "Projects::RecordTargetPlatformsWorker",
        feature_category: "projects",
        urgency: "low"
      }
    ]
  end

  describe ".initialize_execution_slis!" do
    it "initializes the apdex and error rate SLIs" do
      expect(Gitlab::Metrics::Sli::Apdex).to receive(:initialize_sli).with(:sidekiq_execution, labels)
      expect(Gitlab::Metrics::Sli::ErrorRate).to receive(:initialize_sli).with(:sidekiq_execution, labels)

      described_class.initialize_execution_slis!(labels)
    end
  end

  describe ".initialize_queueing_slis!" do
    it "initializes the apdex SLIs" do
      expect(Gitlab::Metrics::Sli::Apdex).to receive(:initialize_sli).with(:sidekiq_queueing, labels)

      described_class.initialize_queueing_slis!(labels)
    end
  end

  describe ".record_execution_apdex" do
    where(:urgency, :duration, :success) do
      "high"      | 5   | true
      "high"      | 11  | false
      "low"       | 295 | true
      "low"       | 400 | false
      "throttled" | 295 | true
      "throttled" | 400 | false
      "not_found" | 295 | true
      "not_found" | 400 | false
    end

    with_them do
      it "increments the apdex SLI with success based on urgency requirement" do
        labels = { urgency: urgency }
        expect(Gitlab::Metrics::Sli::Apdex[:sidekiq_execution]).to receive(:increment).with(
          labels: labels,
          success: success
        )

        described_class.record_execution_apdex(labels, duration)
      end
    end
  end

  describe ".record_execution_error" do
    it "increments the error rate SLI with the given labels and error" do
      labels = { urgency: :throttled }
      error = StandardError.new("something went wrong")

      expect(Gitlab::Metrics::Sli::ErrorRate[:sidekiq_execution]).to receive(:increment).with(
        labels: labels,
        error: error
      )

      described_class.record_execution_error(labels, error)
    end
  end

  describe ".record_queueing_apdex" do
    where(:urgency, :duration, :success) do
      "high"      | 5   | true
      "high"      | 11  | false
      "low"       | 50 | true
      "low"       | 70 | false
      "throttled" | 100 | true
      "throttled" | 1_000_000 | true
      "not_found" | 50 | true
      "not_found" | 70 | false
    end

    with_them do
      it "increments the apdex SLI with success based on urgency requirement" do
        labels = { urgency: urgency }
        expect(Gitlab::Metrics::Sli::Apdex[:sidekiq_queueing]).to receive(:increment).with(
          labels: labels,
          success: success
        )

        described_class.record_queueing_apdex(labels, duration)
      end
    end
  end
end
