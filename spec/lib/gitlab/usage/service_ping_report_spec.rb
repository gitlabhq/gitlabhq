# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::ServicePingReport, :use_clean_rails_memory_store_caching do
  let(:usage_data) { { uuid: "1111" } }

  context 'for output: :all_metrics_values' do
    it 'generates the service ping' do
      expect(Gitlab::UsageData).to receive(:data)

      described_class.for(output: :all_metrics_values)
    end
  end

  context 'for output: :metrics_queries' do
    it 'generates the service ping' do
      expect(Gitlab::UsageDataQueries).to receive(:data)

      described_class.for(output: :metrics_queries)
    end
  end

  context 'for output: :non_sql_metrics_values' do
    it 'generates the service ping' do
      expect(Gitlab::UsageDataNonSqlMetrics).to receive(:data)

      described_class.for(output: :non_sql_metrics_values)
    end
  end

  context 'when using cached' do
    context 'for cached: true' do
      let(:new_usage_data) { { uuid: "1112" } }

      it 'caches the values' do
        allow(Gitlab::UsageData).to receive(:data).and_return(usage_data, new_usage_data)

        expect(described_class.for(output: :all_metrics_values)).to eq(usage_data)
        expect(described_class.for(output: :all_metrics_values, cached: true)).to eq(usage_data)

        expect(Rails.cache.fetch('usage_data')).to eq(usage_data)
      end

      it 'writes to cache and returns fresh data' do
        allow(Gitlab::UsageData).to receive(:data).and_return(usage_data, new_usage_data)

        expect(described_class.for(output: :all_metrics_values)).to eq(usage_data)
        expect(described_class.for(output: :all_metrics_values)).to eq(new_usage_data)
        expect(described_class.for(output: :all_metrics_values, cached: true)).to eq(new_usage_data)

        expect(Rails.cache.fetch('usage_data')).to eq(new_usage_data)
      end
    end

    context 'when no caching' do
      let(:new_usage_data) { { uuid: "1112" } }

      it 'returns fresh data' do
        allow(Gitlab::UsageData).to receive(:data).and_return(usage_data, new_usage_data)

        expect(described_class.for(output: :all_metrics_values)).to eq(usage_data)
        expect(described_class.for(output: :all_metrics_values)).to eq(new_usage_data)

        expect(Rails.cache.fetch('usage_data')).to eq(new_usage_data)
      end
    end
  end
end
