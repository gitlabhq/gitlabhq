# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::DatabaseTransactionSlis, feature_category: :error_budgets do
  using RSpec::Parameterized::TableSyntax
  let(:labels) do
    [
      {
        worker: "Projects::RecordTargetPlatformsWorker",
        feature_category: "projects",
        urgency: "low",
        db_config_name: "main"
      }
    ]
  end

  describe ".initialize_slis!" do
    it "initializes the apdex and error rate SLIs" do
      expect(Gitlab::Metrics::Sli::Apdex).to receive(:initialize_sli).with(:db_transaction, labels)

      described_class.initialize_slis!(labels)
    end
  end

  describe ".record_txn_apdex" do
    where(:db_config_name, :duration, :success) do
      "main"      | 1.99 | true
      "main"      | 2.00 | false
      "ci"        | 2.49 | true
      "ci"        | 2.50 | false
      "not_found" | 0.99 | true
      "not_found" | 1.00 | false
    end

    with_them do
      it "increments the apdex SLI with success based on urgency requirement" do
        labels = { db_config_name: db_config_name }
        expect(Gitlab::Metrics::Sli::Apdex[:db_transaction]).to receive(:increment).with(
          labels: labels,
          success: success
        )

        described_class.record_txn_apdex(labels, duration)
      end
    end
  end
end
