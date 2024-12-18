# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metric do
  let!(:issue) { create(:issue) }

  let(:attributes) do
    {
      data_category: "Operational",
      key_path: "counts.issues",
      description: "Count of Issues created",
      product_group: "plan",
      value_type: "number",
      status: "active",
      time_frame: "all",
      data_source: "database",
      instrumentation_class: "CountIssuesMetric",
      tier: %w[free premium ultimate]
    }
  end

  let(:issue_count_metric_definiton) do
    double(:issue_count_metric_definiton,
      attributes.merge({ raw_attributes: attributes })
    )
  end

  before do
    allow(ApplicationRecord.connection).to receive(:transaction_open?).and_return(false)
  end

  describe '#with_value' do
    it 'returns key_path metric with the corresponding value' do
      expect(described_class.new(issue_count_metric_definiton).with_value).to eq({ counts: { issues: 1 } })
    end
  end

  describe '#with_instrumentation' do
    it 'returns key_path metric with the corresponding generated query' do
      expect(described_class.new(issue_count_metric_definiton).with_instrumentation).to eq({ counts: { issues: "SELECT COUNT(\"issues\".\"id\") FROM \"issues\"" } })
    end
  end

  context 'unavailable metric' do
    let(:instrumentation_class) { "UnavailableMetric" }
    let(:issue_count_metric_definiton) do
      double(:issue_count_metric_definiton,
        attributes.merge({ raw_attributes: attributes, instrumentation_class: instrumentation_class })
      )
    end

    before do
      unavailable_metric_class = Class.new(Gitlab::Usage::Metrics::Instrumentations::CountIssuesMetric) do
        def available?
          false
        end
      end

      stub_const("Gitlab::Usage::Metrics::Instrumentations::#{instrumentation_class}", unavailable_metric_class)
    end

    [:with_value, :with_instrumentation].each do |method_name|
      describe "##{method_name}" do
        it 'returns an empty hash' do
          expect(described_class.new(issue_count_metric_definiton).public_send(method_name)).to eq({})
        end
      end
    end
  end
end
