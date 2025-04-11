# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::ClickHouseConfiguredMetric, feature_category: :database do
  using RSpec::Parameterized::TableSyntax

  where(:clickhouse_configured, :expected_value) do
    false | false
    true  | true
  end

  with_them do
    before do
      allow(::Gitlab::ClickHouse).to receive(:configured?).and_return(clickhouse_configured)
    end

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'none' }
  end
end
