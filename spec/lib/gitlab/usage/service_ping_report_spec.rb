# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::ServicePingReport, :use_clean_rails_memory_store_caching do
  let(:usage_data) { { uuid: "1111", counts: { issue: 0 } } }

  context 'when feature merge_service_ping_instrumented_metrics enabled' do
    before do
      stub_feature_flags(merge_service_ping_instrumented_metrics: true)

      allow_next_instance_of(Gitlab::Usage::ServicePing::PayloadKeysProcessor) do |instance|
        allow(instance).to receive(:missing_key_paths).and_return([])
      end

      allow_next_instance_of(Gitlab::Usage::ServicePing::InstrumentedPayload) do |instance|
        allow(instance).to receive(:build).and_return({})
      end
    end

    context 'all_metrics_values' do
      it 'generates the service ping when there are no missing values' do
        expect(Gitlab::UsageData).to receive(:data).and_return(usage_data)
        expect(described_class.for(output: :all_metrics_values)).to eq({ uuid: "1111", counts: { issue: 0 } })
      end

      it 'generates the service ping with the missing values' do
        expect_next_instance_of(Gitlab::Usage::ServicePing::PayloadKeysProcessor, usage_data) do |instance|
          expect(instance).to receive(:missing_instrumented_metrics_key_paths).and_return(['counts.boards'])
        end

        expect_next_instance_of(Gitlab::Usage::ServicePing::InstrumentedPayload, ['counts.boards'], :with_value) do |instance|
          expect(instance).to receive(:build).and_return({ counts: { boards: 1 } })
        end

        expect(Gitlab::UsageData).to receive(:data).and_return(usage_data)
        expect(described_class.for(output: :all_metrics_values)).to eq({ uuid: "1111", counts: { issue: 0, boards: 1 } })
      end
    end

    context 'for output: :metrics_queries' do
      it 'generates the service ping' do
        expect(Gitlab::UsageData).to receive(:data).and_return(usage_data)

        described_class.for(output: :metrics_queries)
      end
    end

    context 'for output: :non_sql_metrics_values' do
      it 'generates the service ping' do
        expect(Gitlab::UsageData).to receive(:data).and_return(usage_data)

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

  context 'when feature merge_service_ping_instrumented_metrics disabled' do
    before do
      stub_feature_flags(merge_service_ping_instrumented_metrics: false)
    end

    context 'all_metrics_values' do
      it 'generates the service ping when there are no missing values' do
        expect(Gitlab::UsageData).to receive(:data).and_return(usage_data)
        expect(described_class.for(output: :all_metrics_values)).to eq({ uuid: "1111", counts: { issue: 0 } })
      end
    end

    context 'for output: :metrics_queries' do
      it 'generates the service ping' do
        expect(Gitlab::UsageData).to receive(:data).and_return(usage_data)

        described_class.for(output: :metrics_queries)
      end
    end

    context 'for output: :non_sql_metrics_values' do
      it 'generates the service ping' do
        expect(Gitlab::UsageData).to receive(:data).and_return(usage_data)

        described_class.for(output: :non_sql_metrics_values)
      end
    end
  end
end
