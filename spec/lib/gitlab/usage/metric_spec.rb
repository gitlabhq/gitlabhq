# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metric do
  let!(:issue) { create(:issue) }

  let(:attributes) do
    {
      data_category: "Operational",
      key_path: "counts.issues",
      description: "Count of Issues created",
      product_section: "dev",
      product_stage: "plan",
      product_group: "group::plan",
      product_category: "issue_tracking",
      value_type: "number",
      status: "data_available",
      time_frame: "all",
      data_source: "database",
      instrumentation_class: "CountIssuesMetric",
      distribution: %w(ce ee),
      tier: %w(free premium ultimate)
    }
  end

  let(:issue_count_metric_definiton) do
    double(:issue_count_metric_definiton,
      attributes.merge({ attributes: attributes })
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
end
